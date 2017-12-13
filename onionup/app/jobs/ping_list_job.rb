class PingListJob < ApplicationJob
  queue_as :default

  def perform(list)
    @sites = list
    #make threadsafe pings queue and finished pings queu. Multithreads didnt like me instantiating Ping.new() inside a thread
    pings = Queue.new
    finished_ping = Queue.new
    @sites.each do |site| 
      pings << Ping.new
    end
    #make new thread for every site: get a new ping, ping the site, apply attributes to ping and put it in finished_ping queue
    #pretty sure the threadsafe queues are what made this work. 
    threads = @sites.map do |site|
      Thread.new do
          ping = pings.pop
          ping.site_id = site.id
          startTime = Time.now
            res = site.ping
          endTime = Time.now
          timeElapsed = (endTime - startTime)*1000
          ping.responseTime = timeElapsed
          if (res)
            ping.status = true;
          else
            ping.status = false;
          end
          finished_ping.push(ping)
      end
    end
    #wait for threads to finish
    threads.each{|thr| thr.join}    
    #save every ping
    while (!finished_ping.empty?)
      finished_ping.pop(true).save!
    end
  end

end
