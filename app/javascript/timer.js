// app/javascript/timer.js
function initTimer() {
  const timerElement = document.getElementById('timer');
  const startButton = document.getElementById('start-timer');
  
  if (!timerElement || !startButton) return;
  
  let timeLeft = 30 * 60; // 30分（秒単位）
  let timerInterval;
  
  function updateTimer() {
    const minutes = Math.floor(timeLeft / 60);
    const seconds = timeLeft % 60;
    timerElement.textContent = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    
    if (timeLeft <= 0) {
      clearInterval(timerInterval);
      alert('時間切れです！');
    } else {
      timeLeft--;
    }
  }
  
  startButton.addEventListener('click', function() {
    clearInterval(timerInterval);
    timeLeft = 30 * 60;
    updateTimer();
    timerInterval = setInterval(updateTimer, 1000);
    this.disabled = true;
    
    // 編集エリアにフォーカス
    const contentTextarea = document.getElementById('post-content');
    if (contentTextarea) {
      contentTextarea.focus();
    }
  });
}

document.addEventListener('DOMContentLoaded', initTimer);
document.addEventListener('turbo:load', initTimer);