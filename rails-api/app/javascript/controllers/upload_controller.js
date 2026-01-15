import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"

// Connects to data-controller="upload"
export default class extends Controller {
  static targets = ["input", "dropzone", "progress", "progressBar", "status"]
  static values = {
    url: String,
    studySetId: Number
  }

  connect() {
    console.log("Upload controller connected")
    this.setupDragAndDrop()
  }

  setupDragAndDrop() {
    if (!this.hasDropzoneTarget) return

    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      this.dropzoneTarget.addEventListener(eventName, this.preventDefaults, false)
    })

    ;['dragenter', 'dragover'].forEach(eventName => {
      this.dropzoneTarget.addEventListener(eventName, () => {
        this.dropzoneTarget.classList.add('border-blue-500', 'bg-blue-50')
      }, false)
    })

    ;['dragleave', 'drop'].forEach(eventName => {
      this.dropzoneTarget.addEventListener(eventName, () => {
        this.dropzoneTarget.classList.remove('border-blue-500', 'bg-blue-50')
      }, false)
    })

    this.dropzoneTarget.addEventListener('drop', this.handleDrop.bind(this), false)
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  handleDrop(e) {
    const dt = e.dataTransfer
    const files = dt.files
    this.handleFiles(files)
  }

  selectFile(event) {
    const files = event.target.files
    this.handleFiles(files)
  }

  handleFiles(files) {
    Array.from(files).forEach(file => {
      this.uploadFile(file)
    })
  }

  uploadFile(file) {
    // Validate file
    if (!this.validateFile(file)) {
      return
    }

    this.showProgress()
    this.updateStatus(`Uploading ${file.name}...`)

    const upload = new DirectUpload(
      file,
      this.urlValue || '/rails/active_storage/direct_uploads',
      this
    )

    upload.create((error, blob) => {
      if (error) {
        this.handleError(error)
      } else {
        this.handleSuccess(blob)
      }
    })
  }

  validateFile(file) {
    const maxSize = 50 * 1024 * 1024 // 50MB
    const allowedTypes = ['application/pdf']

    if (file.size > maxSize) {
      this.updateStatus(`Error: File size must be less than 50MB`, 'error')
      return false
    }

    if (!allowedTypes.includes(file.type)) {
      this.updateStatus(`Error: Only PDF files are allowed`, 'error')
      return false
    }

    return true
  }

  // DirectUpload delegate methods
  directUploadWillStoreFileWithXHR(request) {
    request.upload.addEventListener("progress", event => {
      this.updateProgress(event)
    })
  }

  updateProgress(event) {
    if (!event.lengthComputable) return

    const progress = (event.loaded / event.total) * 100

    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${progress}%`
      this.progressBarTarget.setAttribute('aria-valuenow', progress)
    }

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = `Uploading... ${Math.round(progress)}%`
    }
  }

  showProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.classList.remove('hidden')
    }
  }

  hideProgress() {
    if (this.hasProgressTarget) {
      this.progressTarget.classList.add('hidden')
    }
  }

  handleSuccess(blob) {
    this.updateStatus('Upload complete! Processing PDF...', 'success')

    // Submit the form or trigger processing
    this.submitProcessingJob(blob)

    // Reset after delay
    setTimeout(() => {
      this.reset()
    }, 2000)
  }

  handleError(error) {
    console.error('Upload error:', error)
    this.updateStatus(`Upload failed: ${error.message}`, 'error')

    setTimeout(() => {
      this.reset()
    }, 5000)
  }

  async submitProcessingJob(blob) {
    if (!this.hasStudySetIdValue) {
      console.error('No study set ID provided')
      return
    }

    try {
      const response = await fetch('/api/v1/study_materials', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          study_material: {
            study_set_id: this.studySetIdValue,
            file_blob_id: blob.signed_id
          }
        })
      })

      if (!response.ok) {
        throw new Error('Processing request failed')
      }

      const data = await response.json()
      this.subscribeToProcessing(data.id)
    } catch (error) {
      this.handleError(error)
    }
  }

  subscribeToProcessing(materialId) {
    // Subscribe to Action Cable for processing updates
    if (typeof App === 'undefined' || !App.cable) {
      console.warn("Action Cable not available")
      return
    }

    this.processingSubscription = App.cable.subscriptions.create(
      {
        channel: "StudyChannel",
        material_id: materialId
      },
      {
        received: (data) => {
          this.handleProcessingUpdate(data)
        }
      }
    )
  }

  handleProcessingUpdate(data) {
    if (data.status === 'completed') {
      this.updateStatus('PDF processing complete!', 'success')
      this.processingSubscription?.unsubscribe()

      // Reload the page or update UI
      setTimeout(() => {
        window.location.reload()
      }, 1500)
    } else if (data.status === 'failed') {
      this.updateStatus('PDF processing failed', 'error')
      this.processingSubscription?.unsubscribe()
    } else {
      this.updateStatus(data.message || 'Processing...', 'info')
    }
  }

  updateStatus(message, type = 'info') {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message

    // Update styling based on type
    this.statusTarget.classList.remove('text-blue-600', 'text-green-600', 'text-red-600')
    switch(type) {
      case 'success':
        this.statusTarget.classList.add('text-green-600')
        break
      case 'error':
        this.statusTarget.classList.add('text-red-600')
        break
      default:
        this.statusTarget.classList.add('text-blue-600')
    }
  }

  reset() {
    this.hideProgress()
    if (this.hasInputTarget) {
      this.inputTarget.value = ''
    }
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = '0%'
    }
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = ''
    }
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
