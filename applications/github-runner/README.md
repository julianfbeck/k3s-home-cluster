# Bejuforge GitHub runner

The `github-runner-secrets` Kubernetes Secret is provisioned out of band. It
must contain an `ACCESS_TOKEN` key whose GitHub token has `admin:org` access to
the Bejuforge organization.

Do not restore a static `RUNNER_TOKEN`: GitHub registration tokens are
single-use and expire quickly, so the runner will fail after its next pod
restart. The `ACCESS_TOKEN` lets the runner image mint a new registration token
on every startup.

The deployment sets `UNSET_CONFIG_VARS=true`, which removes configuration
credentials from the runner process environment before it accepts jobs.

To rotate the live secret, stream the token into Kubernetes without printing it
or writing it to this repository, then restart the deployment and verify the
runner appears online in the Bejuforge organization.
