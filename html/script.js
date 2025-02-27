let running = false;
let startTime = 0;
let interval;

window.addEventListener('message', function(event) {
    let data = event.data;

    if (data.action === "start") {
        startTime = Date.now();
        running = true;
        document.getElementById('timer-container').style.display = "block";
        interval = setInterval(updateTimer, 10);
    } 
    
    else if (data.action === "update") {
        updateTimer(data.time);
    } 
    
    else if (data.action === "stop") {
        running = false;
        clearInterval(interval);
        document.getElementById('timer-container').style.display = "none";
    }
});

function updateTimer(time) {
    let elapsedTime = time !== undefined ? time : Date.now() - startTime;
    let minutes = Math.floor(elapsedTime / 60000);
    let seconds = Math.floor((elapsedTime % 60000) / 1000);
    let milliseconds = Math.floor((elapsedTime % 1000));

    document.getElementById('timer').innerText = 
        `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(milliseconds).padStart(3, '0')}`;
}
