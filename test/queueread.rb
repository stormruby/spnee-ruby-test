require 'bunny'
require 'optparse'
require 'ostruct'
require 'pp'

class Options

  def parse(args)

    options = OpenStruct.new
    options.verbose = false

    options.q = "customer"
    options.f = ""

    opt_parser = OptionParser.new do |opts|
      opts.banner = "Usage: sim.rb [options]"

      # Boolean switch.
      opts.on("-v", "Run verbosely") do |v|
        options.verbose = v
      end

      # Rule Type

      opts.on("-q Queue", "Queue name") do |q|
        options.q = q
      end

      opts.on("-f File", "File name") do |f|
        options.f = f
      end

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
      end
    end
    opt_parser.parse!(args)
    options
  end
end

class Publisher
    def run(options)
    connection = Bunny.new
    connection.start

    channel = connection.create_channel
    queue_name = options.q
    q = channel.queue(queue_name, :durable => true, :auto_delete => false)

    json_array = []
    q.subscribe do |delivery_info, properties, payload|
      if options.f != ""
        json_array.push(payload)
      else
        puts "[consumer] #{q.name} received a message: #{payload}"
      end
    end
    sleep 1.0
    print json_array.length; puts

    if json_array.length != 0
      filename = options.f
      json_array.each do |item|
        puts(filename)
        File.open(filename.to_s,"a") do |f|
          f.write(item)
        end
      end
      print 'wrote json data to filename ', options.f; puts
    end

    #sleep 3.5
    puts "Disconnecting..."
    connection.close
    end
end


mypublisher = Publisher.new
myoptions = Options.new
options = myoptions.parse(ARGV)
if options.verbose == true
  puts options
end
mypublisher.run(options)
