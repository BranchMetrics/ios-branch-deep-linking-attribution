function getFirstLine(message) {
  const index = message.indexOf('\n');
  if (index === -1) {
    return message;
  }

  return message.slice(0, index);
}

async function getBody({ github, core, context, target }) {
  const res = await github.repos.getLatestRelease({
    owner: context.repo.owner,
    repo: context.repo.repo,
  });

  const latestRelease = res.data;
  const diff = await github.repos.compareCommits({
    owner: context.repo.owner,
    repo: context.repo.repo,
    base: latestRelease.tag_name,
    head: target,
  });

  const commits = diff.data.commits;
  if (!commits.length) {
    return 'No changes';
  }

  const format = (log) => `* ${log.title} (${log.hash}) ${log.name} <${log.email}>`;
  const lines = commits.map((c) => {
    const payload = {
      title: getFirstLine(c.commit.message),
      hash: c.sha.slice(0, 7),
      name: c.commit.author.name,
      email: c.commit.author.email,
    };
    return format(payload);
  });

  return lines.join('\n');
}

/**
 * Create Github Release given the version (provided by a tag)
 */
async function createRelease({ context, core, github, sha, version }) {
  const title = `### Release Note (${version})`;
  const body = await getBody({ github, core, context, target: sha });
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
