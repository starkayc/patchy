import UploadHistory from "./history.js";
import { translate } from "./translations.js";

window.addEventListener("DOMContentLoaded", () => {
  const dropArea = document.getElementById("drop-area");
  const fileInput = document.getElementById("file");
  const uploadStatus = document.getElementById("upload-status-container");
  const history = new UploadHistory();

  // i18n
  const translate_uploadText = translate("js_upload_text");
  const translate_uploadClientError = translate("js_upload_client_error");
  const translate_uploadServerError = translate("js_upload_server_error");
  const translate_uploadUnknownError = translate("js_upload_unknown_error");
  const translate_DeleteError = translate("js_history_delete_error");
  const translate_DeleteSuccess = translate("js_history_delete_success");
<<<<<<< HEAD
  const translate_LinkCopied = translate("js_generic_link_copied_to_clipboard");
  const translate_buttonDelete = translate("js_btn_delete");
  const translate_buttonCopy = translate("js_btn_copy");

  const dropAreaText = document.createElement("p");
  dropAreaText.textContent = translate_uploadText;
  dropAreaText.className = "drop-area-text";
  dropArea?.appendChild(dropAreaText);

  const sizeLimit = dropArea?.dataset.sizeLimit;
  if (sizeLimit) {
    const dropAreaSub = document.createElement("p");
    dropAreaSub.textContent = `Max file size: ${sizeLimit}`;
    dropAreaSub.className = "drop-area-limit";
    dropArea?.appendChild(dropAreaSub);
  }
=======
  const translate_DeletingFile = translate("js_history_delete_deleting_file");
  const translate_LinkCopied = translate("js_generic_link_copied_to_clipboard");
  const translate_buttonDelete = translate("js_btn_delete");
  const translate_buttonCopy = translate("js_btn_copy");
  const translate_buttonCancelUpload = translate("js_btn_cancel_upload");
  const translate_status_uploading = translate("js_status_uploading");
  const translate_status_cancelled = translate("js_status_cancelled");

  const dropAreaText = document.createElement("p");
  dropAreaText.textContent = translate_uploadText;
  dropArea?.appendChild(dropAreaText);
  fileInput?.setAttribute("multiple", "");
>>>>>>> upstream/master
  dropArea?.addEventListener("click", () => fileInput?.click());

  fileInput?.addEventListener(
    "change",
    () => {
      const files = fileInput.files;
      handleFiles(files);
<<<<<<< HEAD
      fileInput.value = "";
=======
>>>>>>> upstream/master
    },
    false,
  );

  ["dragenter", "dragover", "dragleave", "drop"].forEach((eventName) => {
    window.addEventListener(eventName, preventDefaults, false);
  });

  function preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  document.addEventListener("paste", handlePaste, false);
  document.addEventListener("drop", handleDrop, false);

  function handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    handleFiles(files);
  }

  function handlePaste(e) {
    const items = e.clipboardData.items;
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      if (item.kind === "file") {
        const file = item.getAsFile();
        handleFiles([file]);
      }
    }
  }

  function handleFiles(files) {
    if (files.length > 0) {
      for (const file of files) {
        uploadFile(file);
      }
    }
  }

  function uploadFile(file) {
    const url = "/-/upload";
    const xhr = new XMLHttpRequest();

    const uploadContainer = document.createElement("div");
    const statusLink = document.createElement("div");
    const uploadText = document.createElement("a");
<<<<<<< HEAD
    const buttons = document.createElement("div");
    const copyButton = document.createElement("button");
    const deleteButton = document.createElement("button");

    uploadContainer.className = "upload-status";
    uploadContainer.appendChild(uploadText);
    uploadContainer.appendChild(statusLink);
    buttons.appendChild(copyButton);
    buttons.appendChild(deleteButton);
    uploadContainer.appendChild(buttons);
    uploadStatus?.appendChild(uploadContainer);

    uploadText.textContent = "0%";
=======
    const rightButtons = document.createElement("div");
    const leftButtons = document.createElement("div");
    const copyButton = document.createElement("button");
    const deleteButton = document.createElement("button");
    const cancelUploadButton = document.createElement("button");

    uploadContainer.className = "upload-status";
    uploadContainer.id = "upload-status";
    rightButtons.className = "buttons-container right-buttons";
    leftButtons.className = "buttons-container left-buttons";
    rightButtons.appendChild(copyButton);
    rightButtons.appendChild(cancelUploadButton);
    leftButtons.appendChild(deleteButton);
    uploadContainer.appendChild(leftButtons);
    uploadContainer.appendChild(uploadText);
    uploadContainer.appendChild(statusLink);
    uploadContainer.appendChild(rightButtons);
    uploadStatus?.appendChild(uploadContainer);

    uploadText.innerHTML = "0%";
>>>>>>> upstream/master
    uploadText.className = "percent";
    statusLink.className = "status";
    copyButton.className = "button copy-button";
    copyButton.innerHTML = translate_buttonCopy;
    deleteButton.className = "button delete-button";
    deleteButton.innerHTML = translate_buttonDelete;
<<<<<<< HEAD
    copyButton.style.display = "none";
    deleteButton.style.display = "none";
=======
    cancelUploadButton.className = "button cancel-upload-button";
    cancelUploadButton.innerHTML = translate_buttonCancelUpload;
    copyButton.style.display = "none";
    deleteButton.style.display = "none";
    cancelUploadButton.style.display = "none";
    leftButtons.style.display = "none";

    xhr.upload.addEventListener("loadstart", (_) => {
      cancelUploadButton.style.display = "inline";
      statusLink.innerHTML = `<a>${translate_status_uploading}</a>`;
      cancelUploadButton.addEventListener(
        "click",
        () => {
          xhr.abort();
          statusLink.innerHTML = `<a>${translate_status_cancelled}</a>`;
          uploadText.innerHTML = "-";
        },
        { once: true },
      );
    });
>>>>>>> upstream/master

    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) {
        const percentComplete = Math.round((e.loaded / e.total) * 100);
<<<<<<< HEAD
        uploadText.textContent = `${percentComplete}%`;
=======
        uploadText.innerHTML = `${percentComplete}%`;
>>>>>>> upstream/master
      }
    });

    xhr.onerror = () => {
      console.error("Error:", xhr.status, xhr.statusText, xhr.responseText);
      statusLink.textContent = translate_uploadUnknownError;
<<<<<<< HEAD
=======
      cancelUploadButton.style.display = "none";
      uploadText.innerHTML = "-";
>>>>>>> upstream/master
    };

    xhr.onload = () => {
      let deleteKey;
<<<<<<< HEAD
=======
      cancelUploadButton.style.display = "none";
>>>>>>> upstream/master
      if (xhr.status === 200) {
        try {
          const response = xhr.responseText;
          const parsedResponse = JSON.parse(response);
          const fileLink = parsedResponse.link;
          const deleteLink = parsedResponse.deleteLink;
          deleteKey = parsedResponse.deleteKey;
          statusLink.innerHTML = `<a href="${fileLink}" target="_blank">${fileLink}</a>`;
<<<<<<< HEAD
          copyButton.style.display = "inline";
          deleteButton.style.display = "inline";
          copyButton.onclick = () => copyToClipboard(fileLink, copyButton);
          deleteButton.onclick = () =>
            deleteFile(deleteLink, deleteKey, uploadContainer);
          history.add(response);
        } catch (_) {
          statusLink.textContent = translate_uploadUnknownError;
        }
      } else if (xhr.status >= 400 && xhr.status < 500) {
        statusLink.textContent = translate_uploadClientError;
      } else {
        statusLink.textContent = translate_uploadServerError;
=======
          copyButton.style.display = "";
          deleteButton.style.display = "";
          leftButtons.style.display = "";
          uploadText.style.display = "none";
          copyButton.onclick = () => copyToClipboard(fileLink, copyButton);
          deleteButton.onclick = () =>
            deleteFile(deleteLink, deleteKey, statusLink);
          history.add(response);
        } catch (_) {
          statusLink.textContent = translate_uploadUnknownError;
          cancelUploadButton.style.display = "none";
          uploadText.innerHTML = "-";
        }
      } else if (xhr.status >= 400 && xhr.status < 500) {
        statusLink.textContent = translate_uploadClientError;
        cancelUploadButton.style.display = "none";
      } else {
        statusLink.textContent = translate_uploadServerError;
        cancelUploadButton.style.display = "none";
>>>>>>> upstream/master
      }
    };

    // Send file
    const formData = new FormData();
    formData.append("file", file);
    xhr.open("POST", url, true);
    xhr.send(formData);
  }

<<<<<<< HEAD
  function deleteFile(deleteLink, deleteKey, uploadContainer) {
    const url = deleteLink;
    const xhr = new XMLHttpRequest();
    const deleteText = document.createElement("a");
    uploadContainer.innerHTML = "";
    uploadContainer.appendChild(deleteText);
    deleteText.className = "delete-text";
=======
  function deleteFile(deleteLink, deleteKey, statusLink) {
    const url = deleteLink;
    const xhr = new XMLHttpRequest();
>>>>>>> upstream/master

    xhr.onerror = () => {
      console.error(
        "Error deleting file:",
        xhr.status,
        xhr.statusText,
        xhr.responseText,
      );
<<<<<<< HEAD
      deleteText.textContent = translate_DeleteError;
=======
      statusLink.textContent = translate_DeleteError;
>>>>>>> upstream/master
    };

    xhr.onload = () => {
      if (xhr.status === 200) {
<<<<<<< HEAD
        deleteText.textContent = translate_DeleteSuccess;
=======
        statusLink.textContent = translate_DeleteSuccess;
>>>>>>> upstream/master
        history.delete(deleteKey);
      }
    };

    xhr.open("GET", url, true);
    xhr.send();
  }

  function copyToClipboard(text, copyButton) {
    navigator.clipboard.writeText(text);
    const prevState = copyButton.innerHTML;
    copyButton.innerHTML = translate_LinkCopied;
<<<<<<< HEAD
=======
    copyButton.innerHTML = translate_LinkCopied;
>>>>>>> upstream/master
    setTimeout(() => {
      copyButton.innerHTML = prevState;
    }, 2000);
  }
});
