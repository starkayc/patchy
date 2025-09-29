import UploadHistory from "./history.js";
import { translate } from "./translations.js";

window.addEventListener("DOMContentLoaded", () => {
  const dropArea = document.getElementById("drop-area");
  const fileInput = document.getElementById("file");
  const form = document.getElementById("form");
  const uploadStatus = document.getElementById("upload-status-container");
  const history = new UploadHistory();

  // i18n
  const translate_uploadText = translate("js_upload_text");
  const translate_uploadClientError = translate("js_upload_client_error");
  const translate_uploadServerError = translate("js_upload_server_error");
  const translate_DeleteError = translate("js_history_delete_error");
  const translate_DeleteSuccess = translate("js_history_delete_success");
  const translate_LinkCopied = translate("js_generic_link_copied_to_clipboard");
  const translate_buttonDelete = translate("js_btn_delete");
  const translate_buttonCopy = translate("js_btn_copy");
  const translate_deleteKeyDoesNotExist = translate(
    "js_generic_delete_key_does_not_exist"
  );

  form.style.display = "none";

  const dropAreaText = document.createElement("p");
  dropAreaText.textContent = translate_uploadText;
  dropArea.appendChild(dropAreaText);

  dropArea.addEventListener("drop", handleDrop, false);
  dropArea.addEventListener("click", () => fileInput.click());

  fileInput.addEventListener(
    "change",
    () => {
      const files = fileInput.files;
      handleFiles(files);
    },
    false
  );

  document.addEventListener("paste", handlePaste, false);

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
    const buttons = document.createElement("div");
    const copyButton = document.createElement("button");
    const deleteButton = document.createElement("button");

    uploadContainer.className = "upload-status";
    uploadContainer.id = "upload-status";
    uploadContainer.appendChild(uploadText);
    uploadContainer.appendChild(statusLink);
    buttons.appendChild(copyButton);
    buttons.appendChild(deleteButton);
    uploadContainer.appendChild(buttons);
    uploadStatus.appendChild(uploadContainer);

    uploadText.innerHTML = "0%";
    uploadText.className = "percent";
    statusLink.className = "status";
    copyButton.className = "button copy-button";
    copyButton.innerHTML = translate_buttonCopy;
    deleteButton.className = "button delete-button";
    deleteButton.innerHTML = translate_buttonDelete;
    copyButton.style.display = "none";
    deleteButton.style.display = "none";

    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) {
        const percentComplete = Math.round((e.loaded / e.total) * 100);
        uploadText.innerHTML = `${percentComplete}%`;
      }
    });

    xhr.onerror = () => {
      console.error("Error:", xhr.status, xhr.statusText, xhr.responseText);
      statusLink.textContent = translate_uploadUnknownError;
    };

    xhr.onload = () => {
      let deleteKey;
      if (xhr.status === 200) {
        try {
          const response = xhr.responseText;
          const parsedResponse = JSON.parse(response);
          const fileLink = parsedResponse.link;
          const deleteLink = parsedResponse.deleteLink;
          deleteKey = parsedResponse.deleteKey;
          statusLink.innerHTML = `<a href="${fileLink}" target="_blank">${fileLink}</a>`;
          copyButton.style.display = "inline";
          deleteButton.style.display = "inline";
          copyButton.onclick = () => copyToClipboard(fileLink, copyButton);
          deleteButton.onclick = () =>
            deleteFile(deleteLink, deleteKey, uploadContainer);
          history.add(response);
        } catch (error) {
          statusLink.textContent = translate_uploadUnknownError;
        }
      } else if (xhr.status >= 400 && xhr.status < 500) {
        statusLink.textContent = translate_uploadClientError;
      } else {
        statusLink.textContent = translate_uploadServerError;
      }
    };

    // Send file
    const formData = new FormData();
    formData.append("file", file);
    xhr.open("POST", url, true);
    xhr.send(formData);
  }

  function deleteFile(deleteLink, deleteKey, uploadContainer) {
    const url = deleteLink;
    const xhr = new XMLHttpRequest();
    const deleteText = document.createElement("a");
    uploadContainer.innerHTML = "";
    uploadContainer.appendChild(deleteText);
    deleteText.className = "delete-text";

    xhr.onerror = () => {
      console.error(
        "Error deleting file:",
        xhr.status,
        xhr.statusText,
        xhr.responseText
      );
      deleteText.textContent = translate_DeleteError;
    };

    xhr.onload = () => {
      if (xhr.status === 200) {
        deleteText.textContent = translate_DeleteSuccess;
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
    copyButton.innerHTML = translate_LinkCopied;
    setTimeout(() => {
      copyButton.innerHTML = prevState;
    }, 2000);
  }
});
