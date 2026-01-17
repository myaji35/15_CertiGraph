import { Controller } from "@hotwired/stimulus"

// Enhanced upload controller with chunked upload support
export default class extends Controller {
  static targets = [
    "input",
    "dropzone",
    "progress",
    "progressBar",
    "progressText",
    "status",
    "pauseButton",
    "resumeButton",
    "cancelButton",
    "fileList"
  ]

  static values = {
    studySetId: Number,
    chunkSize: { type: Number, default: 5242880 }, // 5MB default
    maxFileSize: { type: Number, default: 524288000 }, // 500MB default
    prepareUrl: String,
    chunkUrl: String,
    completeUrl: String,
    validateUrl: String
  }

  connect() {
    console.log("Chunked upload controller connected")
    this.uploadQueue = []
    this.currentUpload = null
    this.isPaused = false
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
      })
    })

    ;['dragleave', 'drop'].forEach(eventName => {
      this.dropzoneTarget.addEventListener(eventName, () => {
        this.dropzoneTarget.classList.remove('border-blue-500', 'bg-blue-50')
      })
    })

    this.dropzoneTarget.addEventListener('drop', this.handleDrop.bind(this))
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  handleDrop(e) {
    const files = e.dataTransfer.files
    this.handleFiles(files)
  }

  selectFile(event) {
    const files = event.target.files
    this.handleFiles(files)
  }

  handleFiles(files) {
    Array.from(files).forEach(file => {
      if (this.validateFile(file)) {
        this.uploadQueue.push(file)
        this.addFileToList(file)
      }
    })

    // Start uploading if not already uploading
    if (!this.currentUpload && this.uploadQueue.length > 0) {
      this.processNextUpload()
    }
  }

  validateFile(file) {
    // Check file type
    const allowedTypes = ['application/pdf']
    if (!allowedTypes.includes(file.type)) {
      this.showError(`Invalid file type: ${file.name}. Only PDF files are allowed.`)
      return false
    }

    // Check file size
    if (file.size > this.maxFileSizeValue) {
      const maxSizeMB = Math.round(this.maxFileSizeValue / (1024 * 1024))
      this.showError(`File too large: ${file.name}. Maximum size is ${maxSizeMB}MB.`)
      return false
    }

    if (file.size === 0) {
      this.showError(`File is empty: ${file.name}`)
      return false
    }

    return true
  }

  addFileToList(file) {
    if (!this.hasFileListTarget) return

    const fileItem = document.createElement('div')
    fileItem.className = 'file-item p-3 mb-2 bg-gray-50 rounded border'
    fileItem.dataset.filename = file.name

    const sizeInMB = (file.size / (1024 * 1024)).toFixed(2)

    fileItem.innerHTML = `
      <div class="flex items-center justify-between">
        <div class="flex-1">
          <div class="font-medium">${file.name}</div>
          <div class="text-sm text-gray-600">${sizeInMB} MB</div>
        </div>
        <div class="file-status text-sm text-gray-500">Queued</div>
      </div>
      <div class="file-progress hidden mt-2">
        <div class="w-full bg-gray-200 rounded-full h-2">
          <div class="bg-blue-600 h-2 rounded-full transition-all duration-300" style="width: 0%"></div>
        </div>
        <div class="text-xs text-gray-600 mt-1">0%</div>
      </div>
    `

    this.fileListTarget.appendChild(fileItem)
  }

  async processNextUpload() {
    if (this.uploadQueue.length === 0) {
      this.currentUpload = null
      this.updateStatus('All uploads complete!', 'success')
      this.resetControls()
      return
    }

    const file = this.uploadQueue.shift()
    this.currentUpload = {
      file: file,
      uploadId: null,
      uploadType: null,
      chunksUploaded: 0,
      totalChunks: 0,
      abortController: new AbortController()
    }

    this.isPaused = false
    this.showUploadControls()
    this.updateFileStatus(file.name, 'Preparing...')

    try {
      // Step 1: Calculate checksum
      this.updateStatus(`Calculating checksum for ${file.name}...`)
      const checksum = await this.calculateChecksum(file)

      // Step 2: Validate with server
      const isValid = await this.validateWithServer(file, checksum)
      if (!isValid) {
        throw new Error('File validation failed')
      }

      // Step 3: Prepare upload
      const prepareData = await this.prepareUpload(file, checksum)

      this.currentUpload.uploadId = prepareData.upload_id
      this.currentUpload.uploadType = prepareData.upload_type

      // Step 4: Upload file
      if (prepareData.upload_type === 'multipart') {
        await this.uploadMultipart(file, prepareData.presigned_data)
      } else if (prepareData.upload_type === 'chunked') {
        await this.uploadChunked(file)
      } else {
        await this.uploadDirect(file, prepareData.presigned_data)
      }

      // Upload complete
      this.updateFileStatus(file.name, 'Complete', 'success')
      this.updateStatus(`${file.name} uploaded successfully!`, 'success')

      // Process next file
      setTimeout(() => this.processNextUpload(), 1000)

    } catch (error) {
      console.error('Upload error:', error)
      this.updateFileStatus(file.name, 'Failed', 'error')
      this.updateStatus(`Upload failed: ${error.message}`, 'error')

      // Process next file after delay
      setTimeout(() => this.processNextUpload(), 2000)
    }
  }

  async calculateChecksum(file) {
    const buffer = await file.arrayBuffer()
    const hashBuffer = await crypto.subtle.digest('SHA-256', buffer)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    return hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
  }

  async validateWithServer(file, checksum) {
    if (!this.hasValidateUrlValue) return true

    try {
      const response = await fetch(this.validateUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.csrfToken
        },
        body: JSON.stringify({
          file: {
            filename: file.name,
            byte_size: file.size,
            content_type: file.type,
            checksum: checksum
          }
        })
      })

      const data = await response.json()

      if (!response.ok || !data.success) {
        if (data.is_duplicate) {
          this.showError(`Duplicate file: ${file.name} has already been uploaded.`)
        }
        return false
      }

      return true
    } catch (error) {
      console.error('Validation error:', error)
      return true // Don't block upload on validation error
    }
  }

  async prepareUpload(file, checksum) {
    const url = this.prepareUrlValue || `/study_sets/${this.studySetIdValue}/uploads/prepare`

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({
        file: {
          filename: file.name,
          byte_size: file.size,
          content_type: file.type,
          checksum: checksum
        }
      })
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || 'Upload preparation failed')
    }

    const data = await response.json()
    return data
  }

  async uploadDirect(file, presignedData) {
    this.updateStatus(`Uploading ${file.name}...`)
    this.showProgress()

    const xhr = new XMLHttpRequest()

    // Track progress
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const progress = Math.round((e.loaded / e.total) * 100)
        this.updateProgress(progress)
        this.updateFileProgress(file.name, progress)
      }
    })

    return new Promise((resolve, reject) => {
      xhr.addEventListener('load', () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          resolve()
        } else {
          reject(new Error(`Upload failed with status ${xhr.status}`))
        }
      })

      xhr.addEventListener('error', () => reject(new Error('Network error')))
      xhr.addEventListener('abort', () => reject(new Error('Upload aborted')))

      xhr.open('PUT', presignedData.url)

      // Set headers
      Object.entries(presignedData.headers || {}).forEach(([key, value]) => {
        xhr.setRequestHeader(key, value)
      })

      xhr.send(file)

      // Store XHR for pause/cancel
      this.currentUpload.xhr = xhr
    })
  }

  async uploadChunked(file) {
    const totalChunks = Math.ceil(file.size / this.chunkSizeValue)
    this.currentUpload.totalChunks = totalChunks

    this.updateStatus(`Uploading ${file.name} in ${totalChunks} chunks...`)
    this.showProgress()

    for (let chunkNumber = 1; chunkNumber <= totalChunks; chunkNumber++) {
      // Check if paused
      while (this.isPaused) {
        await new Promise(resolve => setTimeout(resolve, 100))
      }

      // Check if cancelled
      if (this.currentUpload.abortController.signal.aborted) {
        throw new Error('Upload cancelled')
      }

      const start = (chunkNumber - 1) * this.chunkSizeValue
      const end = Math.min(start + this.chunkSizeValue, file.size)
      const chunk = file.slice(start, end)

      await this.uploadChunk(chunk, chunkNumber, totalChunks)

      this.currentUpload.chunksUploaded = chunkNumber
      const progress = Math.round((chunkNumber / totalChunks) * 100)
      this.updateProgress(progress)
      this.updateFileProgress(file.name, progress)
    }
  }

  async uploadChunk(chunk, chunkNumber, totalChunks) {
    const url = `/study_sets/${this.studySetIdValue}/uploads/${this.currentUpload.uploadId}/chunk`

    const formData = new FormData()
    formData.append('chunk', chunk)
    formData.append('chunk_number', chunkNumber)
    formData.append('total_chunks', totalChunks)

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': this.csrfToken
      },
      body: formData,
      signal: this.currentUpload.abortController.signal
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || `Chunk ${chunkNumber} upload failed`)
    }

    return response.json()
  }

  async uploadMultipart(file, presignedData) {
    const parts = []
    const totalParts = presignedData.parts.length

    this.updateStatus(`Uploading ${file.name} in ${totalParts} parts...`)
    this.showProgress()

    for (let i = 0; i < totalParts; i++) {
      // Check if paused or cancelled
      while (this.isPaused) {
        await new Promise(resolve => setTimeout(resolve, 100))
      }

      if (this.currentUpload.abortController.signal.aborted) {
        throw new Error('Upload cancelled')
      }

      const partData = presignedData.parts[i]
      const start = (i) * presignedData.chunk_size
      const end = Math.min(start + presignedData.chunk_size, file.size)
      const chunk = file.slice(start, end)

      const etag = await this.uploadPart(chunk, partData.url)
      parts.push({ part_number: partData.part_number, etag: etag })

      const progress = Math.round(((i + 1) / totalParts) * 100)
      this.updateProgress(progress)
      this.updateFileProgress(file.name, progress)
    }

    // Complete multipart upload
    await this.completeMultipartUpload(presignedData.upload_id, parts)
  }

  async uploadPart(chunk, url) {
    const response = await fetch(url, {
      method: 'PUT',
      body: chunk,
      signal: this.currentUpload.abortController.signal
    })

    if (!response.ok) {
      throw new Error(`Part upload failed with status ${response.status}`)
    }

    return response.headers.get('ETag').replace(/"/g, '')
  }

  async completeMultipartUpload(uploadId, parts) {
    const url = `/study_sets/${this.studySetIdValue}/uploads/${this.currentUpload.uploadId}/complete_multipart`

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': this.csrfToken
      },
      body: JSON.stringify({
        upload_id: uploadId,
        parts: parts
      })
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.errors?.join(', ') || 'Failed to complete upload')
    }

    return response.json()
  }

  pauseUpload() {
    this.isPaused = true
    this.updateStatus('Upload paused', 'warning')

    if (this.hasPauseButtonTarget && this.hasResumeButtonTarget) {
      this.pauseButtonTarget.classList.add('hidden')
      this.resumeButtonTarget.classList.remove('hidden')
    }
  }

  resumeUpload() {
    this.isPaused = false
    this.updateStatus('Upload resumed', 'info')

    if (this.hasPauseButtonTarget && this.hasResumeButtonTarget) {
      this.pauseButtonTarget.classList.remove('hidden')
      this.resumeButtonTarget.classList.add('hidden')
    }
  }

  async cancelUpload() {
    if (!this.currentUpload) return

    if (confirm('Are you sure you want to cancel this upload?')) {
      this.currentUpload.abortController.abort()

      // Cancel on server
      if (this.currentUpload.uploadId) {
        try {
          await fetch(`/study_sets/${this.studySetIdValue}/uploads/${this.currentUpload.uploadId}/cancel`, {
            method: 'DELETE',
            headers: {
              'X-CSRF-Token': this.csrfToken
            }
          })
        } catch (error) {
          console.error('Cancel request failed:', error)
        }
      }

      this.updateFileStatus(this.currentUpload.file.name, 'Cancelled', 'warning')
      this.updateStatus('Upload cancelled', 'warning')

      this.currentUpload = null
      this.isPaused = false

      // Process next upload
      if (this.uploadQueue.length > 0) {
        setTimeout(() => this.processNextUpload(), 500)
      } else {
        this.resetControls()
      }
    }
  }

  showUploadControls() {
    if (this.hasPauseButtonTarget) {
      this.pauseButtonTarget.classList.remove('hidden')
    }
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.remove('hidden')
    }
  }

  resetControls() {
    if (this.hasPauseButtonTarget) {
      this.pauseButtonTarget.classList.add('hidden')
    }
    if (this.hasResumeButtonTarget) {
      this.resumeButtonTarget.classList.add('hidden')
    }
    if (this.hasCancelButtonTarget) {
      this.cancelButtonTarget.classList.add('hidden')
    }
    this.hideProgress()
  }

  updateProgress(percentage) {
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${percentage}%`
      this.progressBarTarget.setAttribute('aria-valuenow', percentage)
    }

    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${percentage}%`
    }
  }

  updateFileProgress(filename, percentage) {
    const fileItem = this.fileListTarget?.querySelector(`[data-filename="${filename}"]`)
    if (!fileItem) return

    const progressContainer = fileItem.querySelector('.file-progress')
    const progressBar = progressContainer?.querySelector('div > div')
    const progressText = progressContainer?.querySelector('.text-xs')

    if (progressContainer) {
      progressContainer.classList.remove('hidden')
    }

    if (progressBar) {
      progressBar.style.width = `${percentage}%`
    }

    if (progressText) {
      progressText.textContent = `${percentage}%`
    }
  }

  updateFileStatus(filename, status, type = 'info') {
    const fileItem = this.fileListTarget?.querySelector(`[data-filename="${filename}"]`)
    if (!fileItem) return

    const statusElement = fileItem.querySelector('.file-status')
    if (statusElement) {
      statusElement.textContent = status

      statusElement.classList.remove('text-gray-500', 'text-blue-600', 'text-green-600', 'text-red-600', 'text-yellow-600')

      switch (type) {
        case 'success':
          statusElement.classList.add('text-green-600')
          break
        case 'error':
          statusElement.classList.add('text-red-600')
          break
        case 'warning':
          statusElement.classList.add('text-yellow-600')
          break
        default:
          statusElement.classList.add('text-blue-600')
      }
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
    this.updateProgress(0)
  }

  updateStatus(message, type = 'info') {
    if (!this.hasStatusTarget) return

    this.statusTarget.textContent = message

    this.statusTarget.classList.remove('text-blue-600', 'text-green-600', 'text-red-600', 'text-yellow-600')

    switch (type) {
      case 'success':
        this.statusTarget.classList.add('text-green-600')
        break
      case 'error':
        this.statusTarget.classList.add('text-red-600')
        break
      case 'warning':
        this.statusTarget.classList.add('text-yellow-600')
        break
      default:
        this.statusTarget.classList.add('text-blue-600')
    }
  }

  showError(message) {
    this.updateStatus(message, 'error')
    console.error(message)
  }

  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
