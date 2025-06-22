// This was not made by AI so any logical errors are my fault lol
document.addEventListener("DOMContentLoaded", () => {
  const fileHistoryContainer = document.getElementById("file-history");
  const thumbnailsEnabled = JSON.parse(document.getElementById("thumbnails-enabled").textContent).msg;
  const translate_Filename = translate("js_history_link");
  const translate_Link = translate("js_history_link");
  const translate_DirectLink = translate("js_history_direct_link");
  const translate_DeleteDeletingFile = translate("js_history_delete_deleting_file");
  const translate_DeleteSuccess = translate("js_history_delete_success");
  const translate_DeleteDeleteErrorServerDown = translate("js_history_delete_error_server_down");
  const translate_DeleteDeleteError = translate("js_history_delete_error");
  const translate_DeleteDeleteErrorStatusCode = translate("js_history_delete_error_status_code");
  const translate_DeleteDeleteErrorUnknown = translate("js_history_delete_error_unknown");
  // To delete the message pointing that the history feature is not available
  // without JavaScript
  fileHistoryContainer.innerHTML = '';

  const uploadHistory = JSON.parse(loadHistory());

  uploadHistory.forEach((v) => {
    const fileinfo = JSON.parse(v);
    const fileinfoContainer = document.createElement("div");
    fileinfoContainer.className = "file-info";
    fileinfoContainer.id = fileinfo.id

    const fileinfobox = document.createElement("div");
    fileinfobox.className = "file-info-box";

    const linkContainer = document.createElement("span");
    const linkText = document.createElement("a")
    linkText.textContent = `${translate_Link}: ` 
    const link = document.createElement("a");
    link.href = fileinfo.link;
    link.textContent = fileinfo.link;
    link.target = "_blank";
    linkContainer.appendChild(linkText)
    linkContainer.appendChild(link)

    const directLinkContainer = document.createElement("span");
    const directLinkText = document.createElement("a")
    directLinkText.textContent = `${translate_DirectLink}: `
    const directLink = document.createElement("a");
    directLink.href = fileinfo.directLink;
    directLink.textContent = fileinfo.directLink;
    directLink.target = "_blank";
    directLinkContainer.appendChild(directLinkText)
    directLinkContainer.appendChild(directLink)

    const id = document.createElement("a");
    id.textContent = `ID: ${fileinfo.id}`;

    const filename = document.createElement("a");
    filename.textContent = `${translate_Filename}: ${fileinfo.name}`;

    // Commented out since there is a button to delete the file

    // const deleteLinkContainer = document.createElement("span");
    // const deleteLinkText = document.createElement("a")
    // deleteLinkText.textContent = `${translate_DirectLink}: ` 
    // const deleteLink = document.createElement("a");
    // deleteLink.href = fileinfo.deleteLink;
    // deleteLink.textContent = fileinfo.deleteLink;
    // deleteLink.target = "_blank";
    // deleteLinkContainer.appendChild(deleteLinkText)
    // deleteLinkContainer.appendChild(deleteLink)

    let img = undefined

    if (thumbnailsEnabled) {
      img = document.createElement('img');
      img.src = `/-/thumbnail/${fileinfo.id}.jpg`;
    }

    const buttons = document.createElement("div");
    const deleteButton = document.createElement("button");
    buttons.appendChild(deleteButton)
    deleteButton.className = "button delete-button";
    deleteButton.innerHTML = "Delete";
    deleteButton.style.display = "none";
    deleteButton.style.display = "inline";
    deleteButton.onclick = () => {
      const xhr = new XMLHttpRequest();
      const boxToRemove = document.getElementById(fileinfo.id)
      boxToRemove.innerHTML = ''
      const removeText = document.createElement("a")
      removeText.textContent = translate_DeleteDeletingFile
      boxToRemove.appendChild(removeText)

      xhr.onerror = () => {
        console.error("Error:", xhr.status, xhr.statusText, xhr.responseText);
        removeText.textContent = translate_DeleteDeleteErrorServerDown
      };

      xhr.onload = () => {
        if (xhr.status === 200) {
          try {
            removeText.textContent = translate_DeleteSuccess
            removeFromHistory(fileinfo.deleteKey);
          } catch (error) {
            removeText.textContent = "Error deleting file";
          }
        } else if (xhr.status >= 400 && xhr.status < 500) {
          removeText.textContent = `${translate_DeleteDeleteErrorStatusCode}: ${xhr.status}`;
        } else {
          removeText.textContent = translate_DeleteDeleteErrorUnknown
        }
      }

      xhr.open("GET", fileinfo.deleteLink, false);
      xhr.send();

    };

    fileinfobox.appendChild(linkContainer);
    fileinfobox.appendChild(directLinkContainer);
    // fileinfobox.appendChild(deleteLinkContainer);
    fileinfobox.appendChild(id);
    fileinfobox.appendChild(filename);

    fileinfoContainer.appendChild(fileinfobox)
    if (img !== undefined) {
      fileinfoContainer.appendChild(img)
    }

    fileinfoContainer.appendChild(buttons);
    fileHistoryContainer.appendChild(fileinfoContainer);
  });
});

