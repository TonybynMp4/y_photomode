document.addEventListener('DOMContentLoaded', () => {
    window.addEventListener("message", function (event) {
        if (event.data.message == 'show') {
            document.getElementById('controls-container').style.display = event.data.show ? 'flex' : 'none';
        }

        setLocales();
    });

    const sliders = [
        'fov',
        'roll',
        'dofStart',
        'dofEnd',
        'dofStrength'
    ]

    for (const slider of sliders) {
        const sliderElement = document.getElementById(slider)
        sliderElement.addEventListener('input', function (e) {
            fetch(`https://${GetParentResourceName()}/on${slider.charAt(0).toUpperCase() + slider.slice(1)}Change`, {
                method: 'POST',
                body: JSON.stringify({ [slider]: e.target.value }),
            });
            const valueElement = sliderElement.nextElementSibling
            valueElement.innerText = e.target.value
        });
    }

    document.addEventListener('keydown', function (e) {
        e.preventDefault();
        if (e.key === 'Escape' || e.key === 'Backspace') {
            fetch(`https://${GetParentResourceName()}/onClose`, {
                method: 'POST',
            });
        } else if (e.key === 'h') {
            fetch(`https://${GetParentResourceName()}/onToggleUI`, {
                method: 'POST',
            });
        }
    });

    document.addEventListener('contextmenu', function (e) {
        e.preventDefault();
        fetch(`https://${GetParentResourceName()}/onDisableControls`, {
            method: 'POST',
        });
    });
});

function setLocales() {
    fetch(`https://${GetParentResourceName()}/getLocales`, {
        method: 'POST',
    }).then((locales) => locales.json()).then((locales) => {
        for (const locale in locales) {
            const element = document.getElementById(`label_${locale}`);
            if (element) {
                element.innerText = locales[locale];
            }
        }
    });
}