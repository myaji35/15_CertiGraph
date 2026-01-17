# Service for comprehensive file validation with security checks
class FileValidationService
  attr_reader :file_path, :errors

  # Whitelist of allowed MIME types
  ALLOWED_MIME_TYPES = [
    'application/pdf',
    'application/x-pdf'
  ].freeze

  # File size limits
  MIN_FILE_SIZE = 1.kilobyte
  MAX_FILE_SIZE = 500.megabytes

  # PDF magic numbers (file signatures)
  PDF_SIGNATURES = [
    '%PDF-'.bytes,
    [0x25, 0x50, 0x44, 0x46, 0x2D] # %PDF- in hex
  ].freeze

  def initialize(file_path_or_io)
    @file_path = case file_path_or_io
                 when String
                   file_path_or_io
                 when File, Tempfile
                   file_path_or_io.path
                 else
                   nil
                 end
    @errors = []
  end

  # Main validation method
  def validate!
    validate_file_existence!
    validate_file_size!
    validate_mime_type!
    validate_file_signature!
    validate_pdf_structure!
    scan_for_malware! if clamav_available?

    @errors.empty?
  end

  # Individual validation methods
  def validate_file_existence!
    unless file_path && File.exist?(file_path)
      @errors << "File does not exist"
      raise ValidationError, "File does not exist"
    end
  end

  def validate_file_size!
    size = File.size(file_path)

    if size < MIN_FILE_SIZE
      @errors << "File size too small (minimum #{MIN_FILE_SIZE} bytes)"
      raise ValidationError, "File size too small"
    end

    if size > MAX_FILE_SIZE
      @errors << "File size exceeds maximum limit (#{MAX_FILE_SIZE} bytes)"
      raise ValidationError, "File size too large"
    end

    true
  end

  def validate_mime_type!
    mime_type = detect_mime_type

    unless self.class.allowed_content_type?(mime_type)
      @errors << "Invalid file type: #{mime_type}"
      raise ValidationError, "Invalid file type"
    end

    true
  end

  def validate_file_signature!
    signature = read_file_signature

    unless valid_pdf_signature?(signature)
      @errors << "Invalid PDF file signature"
      raise ValidationError, "Invalid PDF file signature"
    end

    true
  end

  def validate_pdf_structure!
    validate_pdf_integrity!
    true
  rescue StandardError => e
    @errors << "PDF structure validation failed: #{e.message}"
    raise ValidationError, "Invalid PDF structure"
  end

  def validate_pdf_integrity!
    # Check PDF header
    File.open(file_path, 'rb') do |file|
      header = file.read(5)
      unless header == '%PDF-'
        raise StandardError, "Invalid PDF header"
      end

      # Check for EOF marker
      file.seek(-5, IO::SEEK_END)
      eof_region = file.read
      unless eof_region.include?('%%EOF')
        raise StandardError, "Missing PDF EOF marker"
      end
    end

    # Check for PDF structure using pdf-reader (if available)
    if defined?(PDF::Reader)
      begin
        reader = PDF::Reader.new(file_path)
        page_count = reader.page_count

        if page_count.zero?
          raise StandardError, "PDF has no pages"
        end

        # Try to access first page to ensure it's readable
        reader.pages.first
      rescue PDF::Reader::MalformedPDFError => e
        raise StandardError, "Malformed PDF: #{e.message}"
      end
    end

    true
  end

  def scan_for_malware!
    return true unless clamav_available?

    result = `clamdscan --no-summary #{Shellwords.escape(file_path)} 2>&1`
    exit_code = $?.exitstatus

    case exit_code
    when 0
      true # Clean
    when 1
      @errors << "Malware detected in file"
      raise ValidationError, "Malware detected"
    else
      Rails.logger.warn("ClamAV scan failed with exit code #{exit_code}: #{result}")
      # Don't fail upload if scanner has issues, but log it
      true
    end
  end

  # Check for duplicate files based on checksum
  def check_duplicate(study_set_id)
    checksum = calculate_checksum

    StudyMaterial.where(study_set_id: study_set_id, file_checksum: checksum)
                 .where.not(upload_status: ['failed', 'cancelled'])
                 .exists?
  end

  def calculate_checksum
    Digest::MD5.file(file_path).hexdigest
  end

  # Class methods for static validation
  def self.allowed_content_type?(content_type)
    ALLOWED_MIME_TYPES.include?(content_type)
  end

  def self.validate_upload_params!(params)
    errors = []

    unless params[:filename].present?
      errors << "Filename is required"
    end

    unless params[:byte_size].present? && params[:byte_size].to_i > 0
      errors << "File size is required and must be greater than 0"
    end

    unless params[:content_type].present? && allowed_content_type?(params[:content_type])
      errors << "Invalid content type"
    end

    if params[:byte_size].to_i > MAX_FILE_SIZE
      errors << "File size exceeds maximum limit"
    end

    if errors.any?
      raise ValidationError, errors.join(', ')
    end

    true
  end

  private

  def detect_mime_type
    # Use multiple methods to detect MIME type
    mime_type = nil

    # Method 1: file command (most reliable)
    if system('which file > /dev/null 2>&1')
      output = `file --mime-type -b #{Shellwords.escape(file_path)}`.strip
      mime_type = output if output.present?
    end

    # Method 2: Marcel gem (Rails default)
    mime_type ||= Marcel::MimeType.for(Pathname.new(file_path))

    # Method 3: Extension-based fallback
    mime_type ||= Rack::Mime.mime_type(File.extname(file_path))

    mime_type
  end

  def read_file_signature
    File.open(file_path, 'rb') do |file|
      file.read(5).bytes
    end
  end

  def valid_pdf_signature?(signature)
    PDF_SIGNATURES.any? do |valid_sig|
      signature.first(5) == valid_sig
    end
  end

  def clamav_available?
    @clamav_available ||= system('which clamdscan > /dev/null 2>&1')
  end

  class ValidationError < StandardError; end
end
