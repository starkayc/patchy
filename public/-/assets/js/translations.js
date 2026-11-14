<<<<<<< HEAD
=======
/* @license magnet:?xt=urn:btih:0b31508aeb0634b347b8270c7bee4d411b5d4109&dn=agpl-3.0.txt AGPL-3.0 */
>>>>>>> upstream/master
export function translate(elementId) {
  const elementName = `_translate-${elementId}`;
  const element = document.getElementById(elementName);

  if (element) {
    try {
      return JSON.parse(element.textContent).msg;
    } catch (_) {
<<<<<<< HEAD
      return null;
    }
  } else {
    return null;
  }
}
=======
      return elementName;
    }
  } else {
    return elementName;
  }
}
/* @license-end */
>>>>>>> upstream/master
