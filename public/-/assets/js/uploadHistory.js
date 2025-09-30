import UploadHistory from "./history.js";
import { translate } from "./translations.js";

window.addEventListener("DOMContentLoaded", () => {
  const CONFIGElement = document.getElementById("patchy-config");
  let CONFIG;
  if (CONFIGElement) {
    CONFIG = JSON.parse(CONFIGElement.textContent);
  }

  const fileHistoryContainer = document.getElementById("file-history");
  if (fileHistoryContainer == null) {
    throw new Error("'file-history' element id not found");
  }
  const history = new UploadHistory();
  const currentTime = Math.ceil(new Date().getTime() / 1000);

  // i18n
  const translate_Filename = translate("js_history_filename");
  const translate_Link = translate("js_history_link");
  const translate_Empty = translate("js_history_empty");
  const translate_uploadedAt = translate("js_history_uploaded_at");
  const translate_expiresAt = translate("js_history_expires_at");
  const translate_DirectLink = translate("js_history_direct_link");
  const translate_DeletingFile = translate("js_history_delete_deleting_file");
  const translate_DeleteSuccess = translate("js_history_delete_success");
  const translate_DeleteErrorServerDown = translate(
    "js_history_delete_error_server_down"
  );
  const translate_DeleteError = translate("js_history_delete_error");
  const translate_DeleteErrorStatusCode = translate(
    "js_history_delete_error_status_code"
  );
  const translate_DeleteError404 = translate("js_history_delete_error_404");
  const translate_DeleteErrorUnknown = translate(
    "js_history_delete_error_unknown"
  );
  const translate_DeleteFromHistory = translate(
    "js_history_delete_from_history"
  );
  const translate_buttonDelete = translate("js_btn_delete");

  // To delete the message pointing that the history feature is not available
  // without JavaScript
  fileHistoryContainer.innerHTML = "";

  const historyList = history.list();

  if (historyList.length <= 0) {
    fileHistoryContainer.innerHTML = `<a>${translate_Empty}</a>`;
  }

  historyList.forEach((v) => {
    const fileinfo = JSON.parse(v);
    const expiresAt = fileinfo.expiresAt;
    const uploadedAt = fileinfo.uploadedAt;

    if (expiresAt) {
      if (expiresAt < currentTime) {
        history.delete(fileinfo.deleteKey);
        return;
      }
    }

    const fileinfoContainer = document.createElement("div");
    fileinfoContainer.className = "file-info";
    fileinfoContainer.id = fileinfo.id;

    const fileinfobox = document.createElement("div");
    fileinfobox.className = "file-info-box";

    const linkContainer = document.createElement("span");
    const linkText = document.createElement("a");
    linkText.textContent = `${translate_Link}: `;
    const link = document.createElement("a");
    link.href = fileinfo.link;
    link.textContent = fileinfo.link;
    link.target = "_blank";
    linkContainer.appendChild(linkText);
    linkContainer.appendChild(link);

    const directLinkContainer = document.createElement("span");
    const directLinkText = document.createElement("a");
    directLinkText.textContent = `${translate_DirectLink}: `;
    const directLink = document.createElement("a");
    directLink.href = fileinfo.directLink;
    directLink.textContent = fileinfo.directLink;
    directLink.target = "_blank";
    directLinkContainer.appendChild(directLinkText);
    directLinkContainer.appendChild(directLink);

    const id = document.createElement("a");
    id.textContent = `ID: ${fileinfo.id}`;

    const filename = document.createElement("a");
    filename.textContent = `${translate_Filename}: ${fileinfo.name}`;

    fileinfobox.appendChild(linkContainer);
    fileinfobox.appendChild(directLinkContainer);
    // fileinfobox.appendChild(deleteLinkContainer);
    fileinfobox.appendChild(id);
    fileinfobox.appendChild(filename);

    if (uploadedAt) {
      const uploadedAtElement = document.createElement("a");
      const uploadedAtDate = new Date(fileinfo.uploadedAt * 1000);
      uploadedAtElement.textContent = `${translate_uploadedAt}: ${uploadedAtDate.toLocaleString()}`;
      fileinfobox.appendChild(uploadedAtElement);
    }

    if (expiresAt) {
      const expiresAtElement = document.createElement("a");
      const expiresAtDate = new Date(expiresAt * 1000);
      expiresAtElement.textContent = `${translate_expiresAt}: ${expiresAtDate.toLocaleString()}`;
      fileinfobox.appendChild(expiresAtElement);
    }

    if (CONFIG.thumbnailsEnabled) {
      const img = document.createElement("img");
      img.className = "img";
      img.src = `/-/thumbnail/${fileinfo.id}.jpg`;

      fileinfoContainer.appendChild(img);
    }

    const buttons = document.createElement("div");
    const deleteButton = document.createElement("button");
    buttons.appendChild(deleteButton);
    deleteButton.className = "button delete-button";
    deleteButton.innerHTML = translate_buttonDelete;
    deleteButton.style.display = "none";
    deleteButton.style.display = "inline";
    deleteButton.onclick = () => {
      const xhr = new XMLHttpRequest();

      const boxToRemove = document.getElementById(fileinfo.id);
      const removeText = document.createElement("a");
      removeText.textContent = translate_DeletingFile;
      if (boxToRemove) {
        boxToRemove.innerHTML = "";
        boxToRemove.appendChild(removeText);
      } else {
        console.error(`no element with id '${boxToRemove}' exists`)
      }

      xhr.onerror = () => {
        console.error("Error:", xhr.status, xhr.statusText, xhr.responseText);
        removeText.textContent = translate_DeleteErrorServerDown;
      };

      xhr.onload = () => {
        if (xhr.status === 200) {
          try {
            removeText.textContent = translate_DeleteSuccess;
            history.delete(fileinfo.deleteKey);
          } catch (error) {
            removeText.textContent = translate_DeleteError;
          }
        } else if (xhr.status === 404) {
          removeText.textContent = `${translate_DeleteError404}, ${translate_DeleteFromHistory}`;
          history.delete(fileinfo.deleteKey);
        } else if (xhr.status >= 400 && xhr.status < 500) {
          removeText.textContent = `${translate_DeleteErrorStatusCode}: ${xhr.status}`;
        } else {
          removeText.textContent = translate_DeleteErrorUnknown;
        }
      };

      xhr.open("GET", fileinfo.deleteLink, false);
      xhr.send();
    };

    fileinfoContainer.appendChild(fileinfobox);
    fileinfoContainer.appendChild(buttons);
    fileHistoryContainer?.appendChild(fileinfoContainer);
  });
});
