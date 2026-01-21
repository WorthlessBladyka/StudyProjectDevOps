// Основной объект приложения
const nginxTester = {
    // История запросов
    requestHistory: JSON.parse(localStorage.getItem('nginxTestHistory')) || [],
    
    // Инициализация приложения
    init: function() {
        this.setupEventListeners();
        this.updateStatus();
        this.loadRequestHistory();
        this.updateCurrentYear();
        
        // Автоматическая проверка соединения при загрузке
        setTimeout(() => this.testConnection(), 1000);
    },
    
    // Установка обработчиков событий
    setupEventListeners: function() {
        // Кнопка проверки соединения
        document.getElementById('testConnectionBtn').addEventListener('click', () => {
            this.testConnection();
        });
        
        // Кнопка тестирования API
        document.getElementById('testApiBtn').addEventListener('click', () => {
            this.testApiEndpoint();
        });
        
        // Кнопка теста производительности
        document.getElementById('performanceTestBtn').addEventListener('click', () => {
            const requestCount = parseInt(document.getElementById('requestCount').value) || 5;
            this.runPerformanceTest(requestCount);
        });
        
        // Кнопка отправки запроса
        document.getElementById('sendRequestBtn').addEventListener('click', () => {
            this.sendCustomRequest();
        });
        
        // Кнопка очистки истории
        document.getElementById('clearHistoryBtn').addEventListener('click', () => {
            this.clearHistory();
        });
        
        // Кнопка экспорта истории
        document.getElementById('exportHistoryBtn').addEventListener('click', () => {
            this.exportHistory();
        });
    },
    
    // Обновление статуса на странице
    updateStatus: function() {
        document.getElementById('currentUrl').textContent = window.location.href;
        document.getElementById('protocol').textContent = window.location.protocol;
        document.getElementById('userAgent').textContent = navigator.userAgent;
        
        // Измерение времени загрузки страницы
        if (window.performance && window.performance.timing) {
            const loadTime = window.performance.timing.loadEventEnd - window.performance.timing.navigationStart;
            document.getElementById('loadTime').textContent = `${loadTime} мс`;
        } else {
            document.getElementById('loadTime').textContent = 'Н/Д';
        }
    },
    
    // Тестирование соединения с сервером
    testConnection: function() {
        const resultDiv = document.getElementById('connectionResult');
        const statusIndicator = document.getElementById('statusIndicator');
        const statusText = document.getElementById('statusText');
        
        resultDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Проверка соединения с сервером...';
        
        // Записываем время начала запроса
        const startTime = performance.now();
        
        // Простой запрос к текущему серверу
        fetch(window.location.pathname, {
            method: 'HEAD',
            cache: 'no-cache'
        })
        .then(response => {
            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);
            
            // Обновляем статус
            statusIndicator.className = 'status-indicator connected';
            statusText.textContent = 'Сервер доступен';
            
            // Получаем заголовки ответа
            const serverHeader = response.headers.get('server') || 'Неизвестно';
            const contentType = response.headers.get('content-type') || 'Неизвестно';
            const dateHeader = response.headers.get('date') || 'Неизвестно';
            
            let resultHTML = `
                <div style="color: #2ecc71; margin-bottom: 10px;">
                    <i class="fas fa-check-circle"></i> <strong>Сервер доступен!</strong>
                </div>
                <div><strong>Статус:</strong> ${response.status} ${response.statusText}</div>
                <div><strong>Время ответа:</strong> ${responseTime} мс</div>
                <div><strong>Сервер:</strong> ${serverHeader}</div>
                <div><strong>Тип контента:</strong> ${contentType}</div>
                <div><strong>Дата ответа:</strong> ${dateHeader}</div>
            `;
            
            // Проверяем, является ли сервер Nginx
            if (serverHeader.toLowerCase().includes('nginx')) {
                resultHTML += `
                    <div style="margin-top: 10px; color: #27ae60;">
                        <i class="fas fa-check"></i> Сервер работает на Nginx
                    </div>
                `;
            }
            
            resultDiv.innerHTML = resultHTML;
            
            // Добавляем запрос в историю
            this.addToHistory({
                time: new Date().toLocaleTimeString(),
                method: 'HEAD',
                endpoint: window.location.pathname,
                status: response.status,
                responseTime: responseTime
            });
        })
        .catch(error => {
            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);
            
            // Обновляем статус
            statusIndicator.className = 'status-indicator';
            statusText.textContent = 'Сервер недоступен';
            
            resultDiv.innerHTML = `
                <div style="color: #e74c3c; margin-bottom: 10px;">
                    <i class="fas fa-exclamation-circle"></i> <strong>Ошибка соединения!</strong>
                </div>
                <div><strong>Сообщение:</strong> ${error.message}</div>
                <div><strong>Время попытки:</strong> ${responseTime} мс</div>
            `;
            
            // Добавляем запрос в историю
            this.addToHistory({
                time: new Date().toLocaleTimeString(),
                method: 'HEAD',
                endpoint: window.location.pathname,
                status: 'Error',
                responseTime: responseTime
            });
        });
    },
    
    // Тестирование API эндпоинта
    testApiEndpoint: function() {
        const resultDiv = document.getElementById('connectionResult');
        resultDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Тестирование API...';
        
        // Попытка получить данные с несуществующего эндпоинта для теста
        const testEndpoint = '/api/test-' + Date.now();
        const startTime = performance.now();
        
        fetch(testEndpoint)
        .then(response => {
            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);
            
            let resultHTML = `
                <div><strong>Эндпоинт:</strong> ${testEndpoint}</div>
                <div><strong>Статус:</strong> ${response.status} ${response.statusText}</div>
                <div><strong>Время ответа:</strong> ${responseTime} мс</div>
            `;
            
            // Анализируем ответ
            if (response.status === 404) {
                resultHTML = `
                    <div style="color: #f39c12; margin-bottom: 10px;">
                        <i class="fas fa-info-circle"></i> <strong>Страница не найдена (ожидаемо)</strong>
                    </div>
                    ${resultHTML}
                    <div style="margin-top: 10px;">
                        Nginx корректно обработал запрос к несуществующему ресурсу и вернул статус 404.
                    </div>
                `;
            } else {
                resultHTML = `
                    <div style="color: #3498db; margin-bottom: 10px;">
                        <i class="fas fa-info-circle"></i> <strong>Неожиданный ответ</strong>
                    </div>
                    ${resultHTML}
                `;
            }
            
            resultDiv.innerHTML = resultHTML;
            
            // Добавляем запрос в историю
            this.addToHistory({
                time: new Date().toLocaleTimeString(),
                method: 'GET',
                endpoint: testEndpoint,
                status: response.status,
                responseTime: responseTime
            });
        })
        .catch(error => {
            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);
            
            resultDiv.innerHTML = `
                <div style="color: #e74c3c; margin-bottom: 10px;">
                    <i class="fas fa-exclamation-circle"></i> <strong>Ошибка запроса</strong>
                </div>
                <div><strong>Эндпоинт:</strong> ${testEndpoint}</div>
                <div><strong>Сообщение:</strong> ${error.message}</div>
                <div><strong>Время попытки:</strong> ${responseTime} мс</div>
            `;
            
            // Добавляем запрос в историю
            this.addToHistory({
                time: new Date().toLocaleTimeString(),
                method: 'GET',
                endpoint: testEndpoint,
                status: 'Error',
                responseTime: responseTime
            });
        });
    },
    
    // Запуск теста производительности
    runPerformanceTest: function(requestCount) {
        const resultDiv = document.getElementById('performanceResult');
        const progressBar = document.getElementById('progressBar');
        const statsDiv = document.getElementById('performanceStats');
        
        resultDiv.style.display = 'block';
        progressBar.style.width = '0%';
        statsDiv.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Подготовка теста...';
        
        const testEndpoint = window.location.pathname;
        const results = [];
        let completed = 0;
        
        // Функция выполнения одного запроса
        const makeRequest = (index) => {
            return new Promise((resolve) => {
                const startTime = performance.now();
                
                fetch(testEndpoint, {
                    method: 'HEAD',
                    cache: 'no-cache',
                    headers: {
                        'X-Test-Request': `performance-test-${index}`
                    }
                })
                .then(response => {
                    const endTime = performance.now();
                    const responseTime = Math.round(endTime - startTime);
                    
                    results.push({
                        index: index,
                        status: response.status,
                        time: responseTime
                    });
                    
                    completed++;
                    const progress = Math.round((completed / requestCount) * 100);
                    progressBar.style.width = `${progress}%`;
                    
                    resolve();
                })
                .catch(error => {
                    const endTime = performance.now();
                    const responseTime = Math.round(endTime - startTime);
                    
                    results.push({
                        index: index,
                        status: 'Error',
                        time: responseTime,
                        error: error.message
                    });
                    
                    completed++;
                    const progress = Math.round((completed / requestCount) * 100);
                    progressBar.style.width = `${progress}%`;
                    
                    resolve();
                });
            });
        };
        
        // Запуск всех запросов последовательно
        const runSequentialRequests = async () => {
            for (let i = 0; i < requestCount; i++) {
                await makeRequest(i + 1);
            }
            
            // Анализ результатов
            this.analyzePerformanceResults(results);
        };
        
        runSequentialRequests();
    },
    
    // Анализ результатов теста производительности
    analyzePerformanceResults: function(results) {
        const statsDiv = document.getElementById('performanceStats');
        
        if (results.length === 0) {
            statsDiv.innerHTML = '<div style="color: #e74c3c;">Нет результатов для анализа</div>';
            return;
        }
        
        // Вычисляем статистику
        const times = results.map(r => r.time);
        const successful = results.filter(r => r.status === 200 || r.status === 304).length;
        const errors = results.length - successful;
        
        const minTime = Math.min(...times);
        const maxTime = Math.max(...times);
        const avgTime = Math.round(times.reduce((a, b) => a + b, 0) / times.length);
        
        // Сортируем времена для вычисления медианы
        const sortedTimes = [...times].sort((a, b) => a - b);
        const medianTime = sortedTimes[Math.floor(sortedTimes.length / 2)];
        
        // Отображаем результаты
        let resultsHTML = `
            <div style="margin-bottom: 15px;">
                <h4>Результаты теста производительности</h4>
            </div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; margin-bottom: 15px;">
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px;">
                    <div style="font-size: 0.9rem; color: #7f8c8d;">Всего запросов</div>
                    <div style="font-size: 1.8rem; font-weight: bold; color: #3498db;">${results.length}</div>
                </div>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px;">
                    <div style="font-size: 0.9rem; color: #7f8c8d;">Успешных</div>
                    <div style="font-size: 1.8rem; font-weight: bold; color: #2ecc71;">${successful}</div>
                </div>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px;">
                    <div style="font-size: 0.9rem; color: #7f8c8d;">Ошибок</div>
                    <div style="font-size: 1.8rem; font-weight: bold; color: ${errors > 0 ? '#e74c3c' : '#2ecc71'};">${errors}</div>
                </div>
            </div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px;">
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px;">
                    <div style="font-size: 0.9rem; color: #7f8c8d;">Среднее время</div>
                    <div style="font-size: 1.5rem; font-weight: bold; color: #3498db;">${avgTime} мс</div>
                </div>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px;">
                    <div style="font-size: 0.9rem; color: #7f8c8d;">Минимальное</div>
                    <div style="font-size: 1.5rem; font-weight: bold; color: #2ecc71;">${minTime} мс</div>
                </div>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px;">
                    <div style="font-size: 0.9rem; color: #7f8c8d;">Максимальное</div>
                    <div style="font-size: 1.5rem; font-weight: bold; color: #e74c3c;">${maxTime} мс</div>
                </div>
                <div style="background: #f8f9fa; padding: 15px; border-radius: 6px;">
                    <div style="font-size: 0.9rem; color: #7f8c8d;">Медиана</div>
                    <div style="font-size: 1.5rem; font-weight: bold; color: #9b59b6;">${medianTime} мс</div>
                </div>
            </div>
        `;
        
        statsDiv.innerHTML = resultsHTML;
        
        // Добавляем тест в историю
        this.addToHistory({
            time: new Date().toLocaleTimeString(),
            method: 'PERF_TEST',
            endpoint: 'Performance Test',
            status: 'Completed',
            responseTime: avgTime,
            details: `${results.length} requests, ${successful} successful, ${errors} errors`
        });
    },
    
    // Отправка пользовательского запроса
    sendCustomRequest: function() {
        const endpoint = document.getElementById('endpoint').value;
        const method = document.getElementById('requestMethod').value;
        const resultDiv = document.getElementById('requestResult');
        
        const url = endpoint ? endpoint : '/';
        resultDiv.innerHTML = `<i class="fas fa-spinner fa-spin"></i> Отправка ${method} запроса к ${url}...`;
        
        const startTime = performance.now();
        
        // Настройки запроса
        const requestOptions = {
            method: method,
            cache: 'no-cache',
            headers: {
                'X-Test-Request': 'custom-request',
                'Content-Type': 'application/json'
            }
        };
        
        // Для POST и PUT добавляем тело запроса
        if (method === 'POST' || method === 'PUT') {
            requestOptions.body = JSON.stringify({
                test: true,
                timestamp: new Date().toISOString(),
                message: 'Тестовый запрос от Nginx Tester'
            });
        }
        
        fetch(url, requestOptions)
        .then(response => {
            const endTime = performance.now();
            const responseTime = Math.round(endTime - startTime);
            
            // Получаем заголовки
            const headers = [];
            response.headers.forEach((value, key) => {
                headers.push(`${key}: ${value}`);
            });
            
            let resultHTML = `
                <div style="margin-bottom: 10px;">
                    <strong>Запрос:</strong> ${method} ${url}
                </div>
                <div><strong>Статус:</strong> ${response.status} ${response.statusText}</div>
                <div><strong>Время ответа:</strong> ${responseTime} мс</div>
            `;
            
            // Цвет статуса
            let statusColor = '#3498db'; // синий по умолчанию
            if (response.status >= 200 && response.status < 300) {
                statusColor = '#2ecc71'; // зеленый для успеха
            } else if (response.status >= 400 && response.status < 500) {
                statusColor = '#e67