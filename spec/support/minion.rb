require 'libvirt'
require 'erb'

# This class is used to start Minion virtual machines using libvirt.
# Inspired by: https://libvirt.org/ruby/examples/domain_create.rb
class Minion
  GUEST_DISK = File.join(
    File.dirname(File.dirname(File.dirname(__FILE__))), "minion_disk.qcow2")

  STORAGE_POOL_NAME = "minions"

  attr_reader :domain, :volume

  # Returns handlers for all running domains
  def self.all
    conn.list_all_domains
  end

  # Connects to the libvirt instance
  # To connect to a remote instance we could use something like:
  # @libvirt = Libvirt::open("qemu+ssh://username_goes_here@192.168.1.23/system)"
  #
  # We would need to setup the ssh keys to not ask for a password.
  # https://libvirt.org/remote.html
  def self.conn
    Libvirt::open("qemu:///system") # Local instance for now
  end

  def self.storage_pool
    pool = conn.list_all_storage_pools.detect{|p| p.name == STORAGE_POOL_NAME }

    unless pool
      pool = conn.define_storage_pool_xml(minion_storage_pool_xml)
      pool.build # Create the directory
      pool.create # start up the pool
    end

    pool
  end

  # Removes all running domains
  def self.cleanup
    self.all.each{|domain| domain.active? ? domain.destroy : domain.undefine }
    self.storage_pool.list_all_volumes.each(&:delete) rescue retry # tmp fix for "ArgumentError: Expected Connection object"
    self.storage_pool.destroy
    self.storage_pool.undefine
  end

  # This method is used in case we know the name of a domain but we don't
  # have the object instance.
  def self.find_domain(name)
    conn.lookup_domain_by_name(name)
  end

  # Creates a new domain to the libvirt instance and saves the handler to
  # the @domain instance variable.
  # We generate a new UUID to be used both as a name and uuid
  # https://libvirt.org/formatdomain.html#elementsMetadata
  def initialize
    uuid = SecureRandom.uuid
    # https://libvirt.org/ruby/examples/storage.rb
    xml = self.class.minion_volume_xml(uuid)
    @volume = self.class.storage_pool.create_volume_xml(xml)
    xml = self.class.minion_domain_xml(uuid)
    @domain = self.class.conn.create_domain_xml(xml)
  end

  def destroy
    domain.destroy
    volume.delete
  end

  private

  # Returns a KVM xml template for the specified uuid
  def self.minion_domain_xml(uuid)
    template =
      File.read(File.join(File.dirname(__FILE__), 'minion_domain.xml.erb'))

    pool_name = STORAGE_POOL_NAME

    ERB.new(template).result(binding)
  end

  def self.minion_storage_pool_xml
    template =
      File.read(File.join(File.dirname(__FILE__), 'minion_storage_pool.xml.erb'))

    pool_name = STORAGE_POOL_NAME

    ERB.new(template).result(binding)
  end

  def self.minion_volume_xml(uuid)
    template =
      File.read(File.join(File.dirname(__FILE__), 'minion_volume.xml.erb'))

    guest_disk = GUEST_DISK

    ERB.new(template).result(binding)
  end
end
