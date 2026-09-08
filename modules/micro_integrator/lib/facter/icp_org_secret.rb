# Reads back the ICP org secret minted on this node by the
# create-icp-org-secret exec in micro_integrator::init (see manifests/init.pp).
#
# Facts run on the agent, before the catalog is compiled on the master, so
# this is the only way for the master to see a value generated locally by a
# previous Puppet run's exec - hence a custom fact instead of file()/template()
# (which would read from the compiling node, not the agent).
#
# This means the secret only becomes available to the catalog starting from
# the run AFTER the exec creates the file - the run that creates it renders
# deployment.toml without a secret, the next run fills it in.
#
# The path here must match $icp_secret_file in manifests/params.pp.
Facter.add(:icp_org_secret) do
  setcode do
    path = '/etc/wso2/icp-org-secret'
    if File.exist?(path)
      File.read(path).strip
    else
      ''
    end
  end
end
