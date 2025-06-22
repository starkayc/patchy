function translate(elementId) {
    const elementName = `_translate-${elementId}`
    const element = document.getElementById(elementName);

    if (element) {
        try {
            return JSON.parse(element.textContent).msg;
        } catch (error) {
            return null;
        }
    } else {
        return null;
    }
}