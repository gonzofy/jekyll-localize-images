require 'uri'
require 'faraday'

class Localizer

  IMAGE_SELECTOR = /(?<tag>\!\[(?<alt>[^\]]*)\]\((?<url>[^)]*)\))/u

  attr_reader :post_directory, :image_directory

  def initialize(post_directory, image_directory)
    @post_directory = post_directory
    @image_directory = image_directory
  end


  def localize_images
    Dir.foreach(@post_directory) do |file|
      next if !(file.end_with?('md') || file.end_with?('.markdown'))
      transform_file("#{@post_directory}#{File::SEPARATOR}#{file}")
    end
  end


  private


  def local_image_filename(url)
    uri = URI(url)
    "#{image_directory}#{File::SEPARATOR}#{File.basename(uri.path)}"
  end


  # downloads the file locally if it hasn't already been downloaded
  def ensure_local_image(url, local_file)
    return local_file if File.exist?(local_file)

    connection = Faraday.new do |faraday|
      faraday.adapter(Faraday.default_adapter)
    end
    response = download_file_helper(connection, url)
    File.open(local_file, 'wb') { |file| file << response.body }

    local_file
  end

  # helper to make sure that we can follow redirects, which can be important for
  # many of the cloud file sharing services out there.
  def download_file_helper(connection, url)
    response = connection.get do |req|
      req.url(url)
    end

    case response.status
    when 302
      download_file_helper(connection, response['Location'])
    when 200
      response
    else
      raise "Error downloading file: #{response.status}"
    end
  end


  def transform_file(file)
    puts "Transforming #{file}"
    contents = File.read(file, encoding: 'UTF-8')

    # Step 1: get all the images that must be downloaded

    queue = []
    contents.scan(IMAGE_SELECTOR) do |match|
      # skip the ones that are already local
      next unless match[2].start_with?('http')
      queue << match
    end

    # Step 2: download the image locally if it's not already present and edit
    #         content

    queue.each do |transformation|
      tag, alt, url = transformation

      local_image = local_image_filename(url)
      begin
        ensure_local_image(url, local_image)
      rescue
        # can't continue with this particular image.
        puts "Error downloading locally for image: #{transformation.inspect}"
        next
      end

      new_tag = "![#{alt}](/#{local_image})"
      contents.sub!(tag, new_tag)
    end

    # Step 3: replace the file itself

    File.unlink(file)
    File.open(file, "wb", encoding: "UTF-8") { |file| file << contents }
  end



end


localizer = Localizer.new('_posts', 'images')
localizer.localize_images