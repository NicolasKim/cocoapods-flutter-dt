require 'rest-client'

class Remote

  def initialize
    if ENV['FLUTTER_BINARY_SERVER_BASEURL'].nil?
      raise StandardError, "Need 'FLUTTER_BINARY_SERVER_BASEURL' in env"
    end
    @base_url = ENV['FLUTTER_BINARY_SERVER_BASEURL']
  end

  def exist?(name, version, tag)
    uri = URI.join @base_url, "/frameworks/exit/#{name}/#{version}/#{tag}"
    resp = RestClient.get(uri.to_s)
    json = JSON.parse(resp.body)
    json["data"]
  end

  def delete(name, version, tag)
    uri = URI.join @base_url, "/frameworks/#{name}/#{version}/#{tag}"
    resp = RestClient.delete uri.to_s
    json = JSON.parse(resp.body)
    json["status"]['code'] == 0
  end

  def upload(name, version, tag, file)
    uri = URI.join @base_url, "/frameworks"
    resp = RestClient.post(uri.to_s, {
        file: File.new(file, 'rb'),
        name: name,
        version: version,
        tag: tag
    })
    json = JSON.parse(resp.body)
    @base_url + json["data"]['download_url']
  end

  def download_url(name, version, tag)
    uri = URI.join @base_url, "/frameworks/#{name}/#{version}/#{tag}"
    resp = RestClient.get uri.to_s
    json = JSON.parse(resp.body)
    @base_url + json["data"]['download_url']
  end

end