function initWordCounter() {
  const contentTextarea = document.getElementById('post-content');
  const wordCountSpan = document.getElementById('word-count');
  
  if (!contentTextarea || !wordCountSpan) return;
  
  function updateWordCount() {
    const text = contentTextarea.value.replace(/\s+/g, '');
    const count = text.length;
    wordCountSpan.textContent = count;
    
    if (count >= 400 && count <= 700) {
      wordCountSpan.style.color = 'green';
    } else {
      wordCountSpan.style.color = 'red';
    }
  }
  
  contentTextarea.addEventListener('input', updateWordCount);
  updateWordCount();
}

document.addEventListener('DOMContentLoaded', initWordCounter);
document.addEventListener('turbo:load', initWordCounter);