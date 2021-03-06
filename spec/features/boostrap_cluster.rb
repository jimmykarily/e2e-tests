require "spec_helper"

feature "Boostrap cluster" do
  before do
    # In case something went wrong and we have leftovers
    puts "Cleaning up running minions"
    cleanup_minions

    puts "Starting environment"
    start_environment
    login
    puts "Spawning minions"
    spawn_minions 2
  end

  after do
    cleanup_environment
    cleanup_minions
  end

  scenario "it creates a kubernetes cluster" do
    visit "/nodes/index"

    dashboard_container = Container.new("velum-dashboard")

    # Wait until Minions are registered
    command = "rails runner 'ActiveRecord::Base.logger=nil; puts Minion.count'"
    minions_registered = loop_with_timeout(timeout: 15, interval: 1) do
      dashboard_container.command(command)[:stdout].to_i == 2
    end
    expect(minions_registered).to be(true)

    # They should also appear in the UI
    expect(page).to have_content('minion0.k8s.local')
    expect(page).to have_content('minion1.k8s.local')

    click_on 'Bootstrap cluster'

    # Wait until orchestration is complete
    query = "Minion.where(highstate: [Minion.highstates[:applied], Minion.highstates[:failed]]).count"
    command = "rails runner 'ActiveRecord::Base.logger=nil; puts #{query}'"
    orchestration_completed = loop_with_timeout(timeout: 1500, interval: 1) do
      dashboard_container.command(command)[:stdout].to_i == 2
    end
    expect(orchestration_completed).to be(true)

    # All Minions should have been applied the highstate successfully
    query = "Minion.where(highstate: Minion.highstates[:applied]).count"
    command = "rails runner 'ActiveRecord::Base.logger=nil; puts #{query}'"
    expect(dashboard_container.command(command)[:stdout].to_i).to eq(2)

    minions = Minion.all
    applied_roles = minions.map(&:roles).flatten
    expect(applied_roles.sort).to eq(["kube-master", "kube-minion"])

    if minions.first.roles.first == "kube-master"
      master, minion = minions
    else
      minion, master = minions
    end

    # Check that the expected programs are running on each node.
    expected_services = ["/usr/sbin/etcd", "salt-minion", "hyperkube apiserver",
                         "hyperkube scheduler", "hyperkube controller-manager"]
    running_services = []
    expected_services.each { |p| running_services << p if master.running?(p) }
    expect(running_services).to eq(expected_services)

    expected_services = ["/usr/sbin/etcd", "salt-minion", "flannel", "docker",
                         "containerd", "hyperkube proxy", "hyperkube kubelet"]
    running_services = []
    expected_services.each { |p| running_services << p if minion.running?(p) }
    expect(running_services).to eq(expected_services)

    # Sanity checks on the Kubernetes cluster.
    out = master.command("kubectl cluster-info dump --output-directory=/opt/info")[:stdout]
    expect(out).to eq "Cluster info dumped to /opt/info"

    # One minion named after the k8s minion (minion0 or minion1)
    nodes = JSON.parse(master.command("cat /opt/info/nodes.json")[:stdout])
    expect(nodes["items"].first["metadata"]["name"]).to eq minion.command("hostname")[:stdout]

    # The pause image is there.
    # TODO: depending whether it's opensuse or microos, this image will be available or not
    #
    # found = false
    # nodes["items"].first["status"]["images"].each do |images|
    #   images["names"].each { |name| found = true if name == "suse/pause:latest" }
    # end
    # expect(found).to be_truthy

    # Now let's check for etcd
    flags = '--key-file=/etc/pki/minion.key --cert-file=/etc/pki/minion.crt ' \
            '--ca-file=/var/lib/k8s-ca-certificates/cluster_ca.crt ' \
            '--endpoints="https://minion1.k8s.local:2379,https://minion0.k8s.local:2379"'
    out = master.command("etcdctl #{flags} cluster-health")[:stdout]
    expect(out.include?("got healthy result")).to be_truthy
  end
end
