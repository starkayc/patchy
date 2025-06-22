function loadHistory() {
  const uploadHistory = window.localStorage.getItem("upload-history");
  if (!uploadHistory) {
    const init = [];
    const e = JSON.stringify(init);
    window.localStorage.setItem("upload-history", e);
    return window.localStorage.getItem("upload-history");
  } else {
    return uploadHistory;
  }
}

function saveOnHistory(response) {
  let uploadHistory = loadHistory();
  uploadHistory = JSON.parse(uploadHistory);
  uploadHistory.unshift(response);
  const updatedUploadHistory = JSON.stringify(uploadHistory);
  window.localStorage.setItem("upload-history", updatedUploadHistory);
}

function removeFromHistory(deleteKey) {
  let uploadHistory = loadHistory();
  uploadHistory = JSON.parse(uploadHistory);
  uploadHistory.forEach((v, index) => {
    const fileinfo = JSON.parse(v)
    if (fileinfo.deleteKey == deleteKey) {
      uploadHistory.splice(index, 1);
    }
  });
  const updatedUploadHistory = JSON.stringify(uploadHistory);
  window.localStorage.setItem("upload-history", updatedUploadHistory);
}