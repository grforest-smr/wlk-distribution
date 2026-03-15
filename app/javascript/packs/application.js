// Простой JavaScript без Stimulus для проверки
document.addEventListener('DOMContentLoaded', function() {
  console.log('JavaScript загружен!');
  
  // Простой обработчик для кнопки загрузки
  const uploadBtn = document.getElementById('uploadCsv');
  if (uploadBtn) {
    uploadBtn.addEventListener('click', function() {
      alert('Кнопка работает!');
    });
  }
});
