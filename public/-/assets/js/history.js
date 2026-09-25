/* @license magnet:?xt=urn:btih:0b31508aeb0634b347b8270c7bee4d411b5d4109&dn=agpl-3.0.txt AGPL-3.0 */
class UploadHistory {
  static itemName = "upload-history";

  constructor() {
    const localStorageHistory = window.localStorage.getItem(
      UploadHistory.itemName,
    );

    if (!localStorageHistory) {
      const uploadArray = JSON.stringify([]);
      window.localStorage.setItem("upload-history", uploadArray);
    }

    if (localStorageHistory !== null) {
      this.uploadHistory = JSON.parse(localStorageHistory);
    } else {
      this.uploadHistory = [];
    }
  }

  list() {
    return this.uploadHistory;
  }

  add(response) {
    this.uploadHistory.unshift(response);
    const updatedUploadHistory = JSON.stringify(this.uploadHistory);
    window.localStorage.setItem(UploadHistory.itemName, updatedUploadHistory);
  }

  delete(deleteKey) {
    this.uploadHistory.forEach((v, index) => {
      const fileinfo = JSON.parse(v);
      if (fileinfo.deleteKey === deleteKey) {
        this.uploadHistory.splice(index, 1);
      }
    });
    const updatedUploadHistory = JSON.stringify(this.uploadHistory);
    window.localStorage.setItem(UploadHistory.itemName, updatedUploadHistory);
  }
}

export default UploadHistory;
/* @license-end */
