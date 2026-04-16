document.addEventListener('DOMContentLoaded', () => {
  const runCheck = document.getElementById('run-check');
  const switchBtn = document.getElementById('switch-btn');
  const resultSection = document.getElementById('result-section');
  const resultOutput = document.getElementById('result-output');

  if (runCheck) {
    runCheck.addEventListener('click', async () => {
      resultSection.classList.remove('hidden');
      resultOutput.textContent = 'Running upgrade readiness checks...';
      try {
        const response = await fetch('/api/upgrade/check', {method: 'POST'});
        const payload = await response.json();
        resultOutput.textContent = JSON.stringify(payload, null, 2);
      } catch (error) {
        resultOutput.textContent = 'Error: ' + error;
      }
    });
  }

  if (switchBtn) {
    switchBtn.addEventListener('click', async () => {
      resultSection.classList.remove('hidden');
      resultOutput.textContent = 'Switching active deployment...';
      try {
        const response = await fetch('/api/bluegreen/switch', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({reason: 'POC switch'})
        });
        const payload = await response.json();
        resultOutput.textContent = JSON.stringify(payload, null, 2);
        window.location.reload();
      } catch (error) {
        resultOutput.textContent = 'Error: ' + error;
      }
    });
  }
});