// app/javascript/controllers/pdf_upload_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["dropzone", "fileInput", "fileInfo", "fileName", "fileSize", "submitButton"]

    connect() {
        console.log("PDF Upload controller connected")
    }

    dragover(event) {
        event.preventDefault()
        this.dropzoneTarget.classList.add('border-blue-500', 'bg-blue-50')
    }

    dragleave(event) {
        event.preventDefault()
        this.dropzoneTarget.classList.remove('border-blue-500', 'bg-blue-50')
    }

    drop(event) {
        event.preventDefault()
        this.dropzoneTarget.classList.remove('border-blue-500', 'bg-blue-50')

        const files = event.dataTransfer.files
        if (files.length > 0) {
            this.handleFile(files[0])
        }
    }

    fileSelected(event) {
        const file = event.target.files[0]
        if (file) {
            this.handleFile(file)
        }
    }

    handleFile(file) {
        // Validate file type
        if (file.type !== 'application/pdf') {
            alert('PDF 파일만 업로드 가능합니다.')
            return
        }

        // Validate file size (50MB)
        const maxSize = 50 * 1024 * 1024
        if (file.size > maxSize) {
            alert('파일 크기는 50MB를 초과할 수 없습니다.')
            return
        }

        // Display file info
        this.fileNameTarget.textContent = file.name
        this.fileSizeTarget.textContent = this.formatFileSize(file.size)
        this.fileInfoTarget.classList.remove('hidden')
        this.submitButtonTarget.disabled = false
    }

    removeFile(event) {
        event.preventDefault()
        this.fileInputTarget.value = ''
        this.fileInfoTarget.classList.add('hidden')
        this.submitButtonTarget.disabled = true
    }

    submit(event) {
        if (!this.fileInputTarget.files.length) {
            event.preventDefault()
            alert('PDF 파일을 선택해주세요.')
            return
        }

        // Show loading state
        this.submitButtonTarget.disabled = true
        this.submitButtonTarget.textContent = '업로드 중...'
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes'
        const k = 1024
        const sizes = ['Bytes', 'KB', 'MB', 'GB']
        const i = Math.floor(Math.log(bytes) / Math.log(k))
        return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
    }
}
