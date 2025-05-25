// By chatgpt becuase I hate frontend and javascript kill me
document.addEventListener("DOMContentLoaded", () => {
  const dropArea = document.getElementById("drop-area");
  const fileInput = document.getElementById("file");
  const form = document.getElementById("form");
  const uploadStatus = document.getElementById("upload-status");
  form.style.display = "none";

  const dropAreaText = document.createElement("p");
  dropAreaText.textContent = "Click here to upload a file"
  dropArea.appendChild(dropAreaText)

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
    const url = "upload";
    const xhr = new XMLHttpRequest();

    const uploadContainer = document.createElement("div");
    const statusLink = document.createElement("div");
    const uploadText = document.createElement("a");
    const buttons = document.createElement("div");
    const copyButton = document.createElement("button");
    const deleteButton = document.createElement("button");

    uploadContainer.className = "upload-status";
    uploadContainer.appendChild(uploadText);
    uploadContainer.appendChild(statusLink);
    buttons.appendChild(copyButton)
    buttons.appendChild(deleteButton)
    uploadContainer.appendChild(buttons)
    uploadStatus.appendChild(uploadContainer);

    uploadText.innerHTML = "0%";
    uploadText.className = "percent";
    statusLink.className = "status";
    copyButton.className = "button copy-button";
    copyButton.innerHTML = "Copy";
    deleteButton.className = "button delete-button";
    deleteButton.innerHTML = "Delete";
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
      statusLink.textContent = "Error desconocido";
    };

    xhr.onload = () => {
      if (xhr.status === 200) {
        try {
          const response = JSON.parse(xhr.responseText);
          const fileLink = response.link;
          statusLink.innerHTML = `<a href="${fileLink}" target="_blank">${fileLink}</a>`;
          copyButton.style.display = "inline";
          copyButton.onclick = () => copyToClipboard(fileLink);
          deleteButton.style.display = "inline";
          deleteButton.onclick = () => {
            window.open(response.deleteLink, "_blank");
          };
        } catch (error) {
          statusLink.textContent =
            "Error desconocido, habla con el administrador";
        }
      } else if (xhr.status >= 400 && xhr.status < 500) {
        try {
          const errorResponse = JSON.parse(xhr.responseText);
          statusLink.textContent = errorResponse.error || "Error del cliente.";
        } catch (e) {
          statusLink.textContent = "Error del cliente.";
        }
      } else {
        statusLink.textContent = "Error del servidor.";
      }
    };

    // Send file
    const formData = new FormData();
    formData.append("file", file);
    xhr.open("POST", url, true);
    xhr.send(formData);
  }

  function copyToClipboard(text) {
    navigator.clipboard.writeText(text)
  }
});
