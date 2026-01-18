# Python Parser Tasks
namespace :python_parser do
  desc "Check Python dependencies"
  task :check_deps => :environment do
    puts "="*70
    puts "Python Parser Dependency Check"
    puts "="*70

    result = PythonParserBridge.check_dependencies

    puts "\n📊 Results:"
    puts "  Python: #{result[:python_version]}"
    puts "  pdfplumber: #{result[:pdfplumber]}"
    puts "  Parser file: #{result[:parser_exists] ? '✅ Found' : '❌ Not found'}"

    if result[:available]
      puts "\n✅ All dependencies are available!"
      puts "\n🚀 You can now use Python parser for PDF processing."
    else
      puts "\n⚠️  Missing dependencies!"
      puts "\n📝 Install instructions:"
      puts "  pip3 install -r requirements.txt"
    end

    puts "="*70
  end

  desc "Test Python parser with sample PDF"
  task :test, [:pdf_path] => :environment do |t, args|
    pdf_path = args[:pdf_path] || Rails.root.join('tmp/test.pdf')

    unless File.exist?(pdf_path)
      puts "❌ PDF file not found: #{pdf_path}"
      puts "Usage: rake python_parser:test[path/to/file.pdf]"
      exit 1
    end

    puts "="*70
    puts "Testing Python Parser"
    puts "="*70
    puts "📄 PDF: #{pdf_path}"
    puts "📊 Size: #{File.size(pdf_path)} bytes"
    puts ""

    puts "🐍 Starting parse..."
    start_time = Time.current

    parser = PythonParserBridge.new(pdf_path)
    result = parser.parse

    elapsed = (Time.current - start_time).round(2)

    if result[:success]
      puts "✅ Parse successful! (#{elapsed}s)"
      puts ""
      puts "📝 Results:"
      puts "  Questions: #{result[:questions].size}"
      puts "  Parser version: #{result[:metadata][:parser_version]}"
      puts ""

      if result[:questions].any?
        puts "🔍 Sample question:"
        q = result[:questions].first
        puts "  Number: #{q[:question_number]}"
        puts "  Content: #{q[:content][0..100]}..."
        puts "  Options: #{q[:options].size}"
        puts "  Topic: #{q[:topic]}"
      end
    else
      puts "❌ Parse failed!"
      puts "Error: #{result[:error]}"
    end

    puts "="*70
  end

  desc "Install Python dependencies"
  task :install_deps => :environment do
    puts "="*70
    puts "Installing Python Dependencies"
    puts "="*70

    requirements_file = Rails.root.join('requirements.txt')

    unless File.exist?(requirements_file)
      puts "❌ requirements.txt not found"
      exit 1
    end

    puts "📦 Installing from requirements.txt..."
    system("pip3 install -r #{requirements_file}")

    if $?.success?
      puts "\n✅ Installation successful!"
      Rake::Task['python_parser:check_deps'].invoke
    else
      puts "\n❌ Installation failed"
      exit 1
    end
  end
end
