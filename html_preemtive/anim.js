const canvas = document.querySelector("canvas");
const ctx = canvas.getContext("2d");

let w = canvas.width = window.innerWidth;
let h = canvas.height = window.innerHeight;
let time = 0;

function resizeCanvas() {
    w = canvas.width = window.innerWidth;
    h = canvas.height = window.innerHeight;
}
window.addEventListener("resize", resizeCanvas);

function drawWave(yOffset, amplitude, frequency, speed, color, alpha) {
    ctx.beginPath();

    for (let x = 0; x <= w; x += 4) {
        const y =
            yOffset +
            Math.sin(x * frequency + time * speed) * amplitude +
            Math.sin(x * frequency * 0.5 + time * speed * 3.7) * (amplitude * 1.5);

        if (x === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
    }

    ctx.lineTo(w, h);
    ctx.lineTo(0, h);
    ctx.closePath();

    ctx.fillStyle = color;
    ctx.globalAlpha = alpha;
    ctx.fill();
    ctx.globalAlpha = 1;
}

function animate() {
    ctx.clearRect(0, 0, w, h);

    // fondo base
    ctx.fillStyle = "#faf2e5";
    ctx.fillRect(0, 0, w, h);

    // gradiente radial muy sutil
    const gradient = ctx.createRadialGradient(
        w * 0.5, h * 0.45, 100,
        w * 0.5, h * 0.45, Math.max(w, h) * 0.6
    );
    gradient.addColorStop(0, "rgba(145, 157, 109, 0.10)");
    gradient.addColorStop(1, "rgba(250, 242, 229, 0)");

    ctx.fillStyle = gradient;
    ctx.fillRect(0, 0, w, h);

    // capas de ondas suaves
    drawWave(h * 0.72, 18, 0.008, 0.6, "#248442", 0.25);
    drawWave(h * 0.78, 24, 0.006, 0.45, "#215748", 0.20);
    drawWave(h * 0.84, 16, 0.010, 0.35, "#919d6d", 0.12);

    time += 0.01;
    requestAnimationFrame(animate);
}

animate();

