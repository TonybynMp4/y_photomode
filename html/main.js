document.addEventListener('DOMContentLoaded', () => {
    window.addEventListener("message", function (event) {
        if (event.data.message == 'show') {
            document.getElementById('controls-container').style.display = event.data.show ? 'flex' : 'none';
        }
    });

    const sliders = [
        'fov',
        'roll',
        'dof',
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
});