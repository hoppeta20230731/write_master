document.addEventListener('turbo:load', function() {
  initFeedbackPoller();
});

document.addEventListener('DOMContentLoaded', function() {
  initFeedbackPoller();
});

function initFeedbackPoller() {
  // フィードバックエリア要素を取得
  const feedbackArea = document.querySelector('.ai-feedback-area');
  
  // 該当要素がない、または必要なデータ属性がない場合は終了
  if (!feedbackArea || !feedbackArea.dataset.postId) return;
  
  // ステータスを取得
  const status = feedbackArea.dataset.status;
  
  // ステータスが処理中を示す場合のみポーリングを開始
  if (status === 'queued' || status === 'processing') {
    const postId = feedbackArea.dataset.postId;
    
    console.log('ポーリングを開始します: PostID=' + postId);
    
    // 既存のポーリングがあれば停止
    if (window.feedbackPollingInterval) {
      clearInterval(window.feedbackPollingInterval);
    }
    
    // 5秒ごとにステータスをチェック
    window.feedbackPollingInterval = setInterval(function() {
      fetch(`/posts/${postId}/feedback_status`)
        .then(response => {
          if (!response.ok) {
            throw new Error('ステータス取得に失敗しました');
          }
          return response.json();
        })
        .then(data => {
          console.log('ステータス確認:', data);
          // 完了または失敗した場合、ページをリロード
          if (data.status === 'completed' || data.status === 'failed' || data.has_feedback) {
            console.log('処理が完了したためページをリロードします');
            window.location.reload();
          }
        })
        .catch(error => {
          console.error('ポーリングエラー:', error);
        });
    }, 5000); // 5秒間隔
  }
}