const fs = require('fs');

async function uploadAsset({ github, assetName, path, contentType, uploadUrl }) {
  const contentLength = fs.statSync(path).size;
  const contents = fs.readFileSync(path);

  console.log(`Uploading asset ${assetName}, content-length ${contentLength}.`)

  const { data } = await github.repos.uploadReleaseAsset({
    url: uploadUrl + `?name=${encodeURIComponent(assetName)}`,
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
