/**
 * Create Github Release given the version (provided by a tag)
 * prerelease: true to mark the release as a pre-release, e.g. for 4.0.0-beta.3
 */
async function createRelease({ context, core, github, sha, version, prerelease = false }) {
  const title = `### Release Note (${version})`;
  const body = '[Insert ChangeLog update]';
  const releaseBody = `${title}\n\n${body}`;

  const release = {
    owner: context.repo.owner,
    repo: context.repo.repo,
    tag_name: version,
    target_commitish: sha,
    name: version,
    body: releaseBody,
    draft: false,
    prerelease,
  };

  await github.rest.repos.createRelease(release);
}

module.exports = createRelease;
