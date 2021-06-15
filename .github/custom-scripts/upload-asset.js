const fs = require('fs');

async function uploadAsset({ github, assetName, path, contentType, uploadUrl }) {
  const contentLength = fs.statSync(path).size;
  const contents = fs.readFileSync(path);

  const { data } = await github.repos.uploadReleaseAsset({
    url: uploadUrl,
    headers: {
      'content-type': contentType,
      'content-length': contentLength,
    },
    name: assetName,
    file: contents,
  });

  return data;
}

module.exports = uploadAsset;
