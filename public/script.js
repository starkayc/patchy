document.addEventListener("DOMContentLoaded", () => {
    const dropArea = document.getElementById("drop-area");
    const fileInput = document.getElementById("fileElem");
    const uploadStatus = document.getElementById("upload-status");

    // Prevent default drag behaviors
    ["dragenter", "dragover", "dragleave", "drop"].forEach(eventName => {
        dropArea.addEventListener(eventName, preventDefaults, false);
        document.body.addEventListener(eventName, preventDefaults, false);
    });

    // Highlight drop area when item is dragged over
    ["dragenter", "dragover"].forEach(eventName => {
        dropArea.addEventListener(eventName, highlight, false);
    });

    ["dragleave", "drop"].forEach(eventName => {
        dropArea.addEventListener(eventName, unhighlight, false);
    });

    // Handle dropped files
    dropArea.addEventListener("drop", handleDrop, false);
    dropArea.addEventListener("click", () => fileInput.click());

    // Handle file selection
    fileInput.addEventListener("change", () => {
        const files = fileInput.files;
        handleFiles(files);
    }, false);

    // Handle pasted files
    document.addEventListener("paste", handlePaste, false);

    function preventDefaults(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    function highlight() {
        dropArea.classList.add("highlight");
    }

    function unhighlight() {
        dropArea.classList.remove("highlight");
    }

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
        const url = "upload"; // Replace with your upload URL
        const xhr = new XMLHttpRequest();

        // Create a new upload status container and link elements
        const uploadContainer = document.createElement("div");
        const statusLink = document.createElement("div");
        const uploadText = document.createElement("span");
        const copyButton = document.createElement("button");

        uploadContainer.className = "upload-status"; // Use the existing CSS class for styling
        uploadContainer.appendChild(uploadText);
        uploadContainer.appendChild(statusLink);
        uploadContainer.appendChild(copyButton);
        uploadStatus.appendChild(uploadContainer); // Append to the main upload status container

        // Update upload text
        uploadText.innerHTML = "0%";
        uploadText.className = "percent"
        copyButton.className = "copy-button"; // Add class for styling
        copyButton.innerHTML = "Copy Link"; // Set button text
        copyButton.style.display = "none"; // Hide initially

        // Update progress text
        xhr.upload.addEventListener("progress", (e) => {
            if (e.lengthComputable) {
                const percentComplete = Math.round((e.loaded / e.total) * 100);
                uploadText.innerHTML = `${percentComplete}%`; // Update the text with the percentage
            }
        });

        // Handle response
        xhr.onload = () => {
            if (xhr.status === 200) {
                try {
                    const response = JSON.parse(xhr.responseText);
                    const fileLink = response.link; // Assuming the response contains a key 'link'
                    statusLink.innerHTML = `<a href="${fileLink}" target="_blank">${fileLink}</a>`;
                    copyButton.style.display = "inline"; // Show the copy button
                    copyButton.onclick = () => copyToClipboard(fileLink); // Set the copy action
                } catch (error) {
                    statusLink.textContent = "File uploaded but failed to parse response.";
                }
            } else {
                statusLink.textContent = "File upload failed.";
            }
        };

        // Handle errors
        xhr.onerror = () => {
            statusLink.textContent = "An error occurred during the file upload.";
        };

        // Send file
        const formData = new FormData();
        formData.append("file", file);
        xhr.open("POST", url, true);
        xhr.send(formData);
    }

    // Function to copy the link to the clipboard
    function copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(() => {
            // alert("Link copied to clipboard!"); // Notify the user
        }).catch(err => {
            console.error("Failed to copy: ", err);
        });
    }
});
