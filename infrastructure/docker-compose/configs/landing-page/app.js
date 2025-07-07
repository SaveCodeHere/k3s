// Helper functions
function sanitizeHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

// Initialize application
async function initializeApp() {
    try {
        const response = await fetch('config.json'); // <-- Fetch .json
        if (!response.ok) {
            throw new Error('Failed to load configuration');
        }
        const config = await response.json(); // <-- Parse as JSON
        // Wait for configuration to be available    
        if (!config || !config.url || !config.anonKey) {
            throw new Error('Invalid configuration format');
        }
        
        // Initialize Supabase client
        const supabase = window.supabase.createClient(
            config.url,
            config.anonKey
        );


        // Set last update date 
        document.getElementById('lastUpdate').textContent = new Date().toLocaleDateString();

        // Setup auth state listener
        supabase.auth.onAuthStateChange((event, session) => {
            if (session) {
                document.getElementById('userInfo').textContent = 
                    `Signed in as: ${sanitizeHtml(session.user.email)}`;
            } else {
                document.getElementById('userInfo').textContent = '';
            }
        });

        return supabase;
    } catch (error) {
        handleError('Initialization error', error);
        throw error;
    }
}

async function loadServices() {
    try {
        const res = await fetch('services.json');
        if (!res.ok) {
            throw new Error(`Failed to load services: ${res.status} ${res.statusText}`);
        }
        const services = await res.json();
        const grid = document.querySelector('.services-grid');
        grid.innerHTML = '';

        if (!Array.isArray(services) || services.length === 0) {
            grid.innerHTML = '<p style="text-align:center;color:#666;">No services configured</p>';
            return;
        }

        services.forEach(service => {
            if (!service.title || !service.url) {
                console.warn('Invalid service configuration:', service);
                return;
            }
            
            const card = document.createElement('div');
            card.className = `service-card ${sanitizeHtml(service.class || '')}`;
            card.innerHTML = `
                <span class="service-icon">${sanitizeHtml(service.icon)}</span>
                <h3 class="service-title">${sanitizeHtml(service.title)}</h3>
                <p class="service-description">${sanitizeHtml(service.description)}</p>
                <a href="${sanitizeHtml(service.url)}" 
                    class="service-link" 
                    rel="noopener noreferrer">
                    Open ${sanitizeHtml(service.title.split(' ')[0])}
                </a>
            `;
            grid.appendChild(card);
        });

        const addCard = document.createElement('div');
        addCard.className = 'service-card';
        addCard.innerHTML = `
            <span class="service-icon">➕</span>
            <h3 class="service-title">Add New Service</h3>
            <p class="service-description">Configure additional services in your stack</p>
            <a href="#" class="service-link">Coming Soon</a>
        `;
        grid.appendChild(addCard);
    } catch (err) {
        console.error('Service loading error:', err.message);
        document.querySelector('.services-grid').innerHTML = 
            '<p style="text-align:center;color:#666;">Unable to load services. Please try again later.</p>';
    }
}

async function handleAuth(supabase) {
    if (!supabase) {
        console.error('Supabase client not initialized');
        return;
    }

    const urlParams = new URLSearchParams(window.location.search);
    const hashParams = new URLSearchParams(window.location.hash.substring(1));
    
    const token = urlParams.get('token');
    const type = urlParams.get('type');
    const accessToken = hashParams.get('access_token');
    const refreshToken = hashParams.get('refresh_token');

    if (token && type) {
        document.getElementById('authProcessing').classList.add('show');
        
        try {
            if (type === 'invite') {
                const { error } = await supabase.auth.verifyOtp({
                    token_hash: token,
                    type: 'invite'
                });
                
                if (error) throw error;
                
                document.getElementById('authProcessing').classList.remove('show');
                document.getElementById('authSuccess').classList.add('show');
                window.history.replaceState({}, document.title, window.location.pathname);
                
                setTimeout(() => {
                    document.getElementById('authSuccess').classList.remove('show');
                }, 3000);
                
            } else if (type === 'recovery') {
                const { error } = await supabase.auth.verifyOtp({
                    token_hash: token,
                    type: 'recovery'
                });
                
                if (error) throw error;
                window.location.href = '/reset-password';
            }
        } catch (error) {
            console.error('Auth verification error:', error);
            document.getElementById('authProcessing').classList.remove('show');
            alert(`Authentication failed: ${error.message}`);
        }
    }
    
    if (accessToken && refreshToken) {
        try {
            const { error } = await supabase.auth.setSession({
                access_token: accessToken,
                refresh_token: refreshToken
            });
            
            if (error) throw error;
            
            window.history.replaceState({}, document.title, window.location.pathname);
            document.getElementById('authSuccess').classList.add('show');
            setTimeout(() => {
                document.getElementById('authSuccess').classList.remove('show');
            }, 3000);
            
        } catch (error) {
            console.error('Session error:', error);
        }
    }
    
    try {
        const { data: { session } } = await supabase.auth.getSession();
        if (session?.user?.email) {
            document.getElementById('userInfo').textContent = 
                `Signed in as: ${sanitizeHtml(session.user.email)}`;
        }
    } catch (error) {
        console.error('Session check error:', error);
    }
}

// Initialize everything when DOM is ready
document.addEventListener('DOMContentLoaded', async () => {
    try {
        const supabase = await initializeApp();
        if (supabase) {
            await handleAuth(supabase);
            await loadServices();
        }
    } catch (error) {
        handleError('Application startup failed', error);
    }
});

// Error handler
function handleError(context, error) {
    console.error(context + ':', error);
    document.body.innerHTML = `
        <div style="text-align:center;padding:2rem;color:red;">
            <h1>⚠️ ${sanitizeHtml(context)}</h1>
            <p>${sanitizeHtml(error.message)}</p>
        </div>`;
}