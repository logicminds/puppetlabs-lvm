Puppet::Type.type(:physical_volume).provide(:lvm) do
    desc "Manages LVM physical volumes"

    commands :pvcreate  => 'pvcreate', :pvremove => 'pvremove', :pvs => 'pvs'

    def create
        pvcreate(@resource[:name])
    end

    def destroy
        pvremove(@resource[:name])
    end

    def self.pvolumes
      pvols = []
      volumes = pvs().split("\n")
      if volumes.size > 1
        # remove header
        volumes.shift
        volumes.each do | pvol|
          pvols << pvol.strip.split(/\ +/)
        end
      end
      pvols
    end
    
    def self.instances
      pvolumes.map { |vol | new(:name => vol[0], :ensure => :present) }  
    end
    
    def exists?
        pvs(@resource[:name])
    rescue Puppet::ExecutionFailure
        false
    end

end
