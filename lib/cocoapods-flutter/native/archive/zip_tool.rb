require 'zip'

class Zip::File
  def add_dir(entry, dir)
    if File.directory? dir
      entries = Dir.entries(dir) - %w[. ..]
      entries.each do |subentry|
        add_dir "#{entry}/#{subentry}", "#{dir}/#{subentry}"
      end
    else
      add entry, dir
    end
  end
end

class ZipFileGenerator
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(input_dir, entry, zipfile)

    @input_dir = input_dir
    @zipfile = zipfile
    @entry = entry
  end

  # Zip the input directory.
  def write
    entries = Dir.entries(@input_dir) - %w[. ..]
    write_entries entries, @entry, @zipfile
  end

  private

  # A helper method to make the recursion work.
  def write_entries(entries, path, zipfile)
    entries.each do |e|
      zipfile_path = path == '' ? e : File.join(path, e)
      disk_file_path = File.join(@input_dir, zipfile_path)

      if File.directory? disk_file_path
        recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
      else
        put_into_archive(disk_file_path, zipfile, zipfile_path)
      end
    end
  end

  def recursively_deflate_directory(disk_file_path, zipfile, zipfile_path)
    zipfile.mkdir zipfile_path
    subdir = Dir.entries(disk_file_path) - %w[. ..]
    write_entries subdir, zipfile_path, zipfile
  end

  def put_into_archive(disk_file_path, zipfile, zipfile_path)
    zipfile.add(zipfile_path, disk_file_path)
  end
end