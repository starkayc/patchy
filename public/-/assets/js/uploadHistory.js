import UploadHistory from "./history.js";
import { translate } from "./translations.js";

document.addEventListener("DOMContentLoaded", () => {
  const fileHistoryContainer = document.getElementById("file-history");
  const thumbnailsEnabled = JSON.parse(
    document.getElementById("thumbnails-enabled").textContent
  ).msg;
  const history = new UploadHistory();

  // i18n
  const translate_Filename = translate("js_history_filename");
  const translate_Link = translate("js_history_link");
  const translate_Empty = translate("js_history_empty");
  const translate_uploadedAt = translate("js_history_uploaded_at");
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

    const uploadedAt = document.createElement("a");
    const uploadedAtDate = new Date(fileinfo.uploadedAt * 1000);
    uploadedAt.textContent = `${translate_uploadedAt}: ${uploadedAtDate.getFullYear()}-${uploadedAtDate.getMonth()}-${uploadedAtDate.getDay()} ${uploadedAtDate.getHours()}:${uploadedAtDate.getMinutes()}`;

    let img = undefined;

    if (thumbnailsEnabled) {
      img = document.createElement("img");
      img.src = `/-/thumbnail/${fileinfo.id}.jpg`;
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
      boxToRemove.innerHTML = "";
      const removeText = document.createElement("a");
      removeText.textContent = translate_DeletingFile;
      boxToRemove.appendChild(removeText);

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

    fileinfobox.appendChild(linkContainer);
    fileinfobox.appendChild(directLinkContainer);
    // fileinfobox.appendChild(deleteLinkContainer);
    fileinfobox.appendChild(id);
    fileinfobox.appendChild(filename);
    fileinfobox.appendChild(uploadedAt);

    fileinfoContainer.appendChild(fileinfobox);
    if (img !== undefined) {
      fileinfoContainer.appendChild(img);
    }

    fileinfoContainer.appendChild(buttons);
    fileHistoryContainer.appendChild(fileinfoContainer);
  });
});
