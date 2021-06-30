/**
 * Create Github Release given the version (provided by a tag)
 */
async function createRelease({ context, core, github, sha, version }) {
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
    prelease: false,
  };

  await github.repos.createRelease(release);
}

module.exports = createRelease;
