Rails.application.routes.draw do
  # Rutas de autenticación
  devise_for :usuarios, controllers: {
    sessions: 'usuarios/sessions',
    registrations: 'usuarios/registrations'
  }
  
  # Ruta principal
  root 'home#index'
  
  # Rutas protegidas
  authenticate :usuario do
    get '/dashboard', to: 'dashboard#index', as: :dashboard
    
    # Perfil de usuario
    resource :perfil, only: [:show, :edit, :update]
    
    # Sesiones de laboratorio y consola
    resources :sesion_laboratorios do
      member do
        post :reset
        post :pausar
        post :completar
      end
      
      resource :consola, only: [:show] do
        get 'terminal', to: 'wetty#show'
      end
    end
    
    # Cursos y recursos anidados
    resources :cursos do
      member do
        post :inscribir_estudiante
        delete :desinscribir_estudiante
        get :estudiantes
        get :metricas
      end
      
      # Laboratorios anidados con shallow routing
      resources :laboratorios, shallow: true
      
      # Quizzes anidados con shallow routing
      resources :quizzes, shallow: true do
        resources :preguntas, controller: 'quiz_preguntas', shallow: true do
          resources :opciones, controller: 'quiz_opciones', shallow: true
          
          collection do
            post :reordenar
          end
        end
        
        resources :intentos, controller: 'intentos_quiz', shallow: true do
          member do
            post :iniciar
            post :finalizar
            get :resultados
            post :responder
          end
        end
        
        member do
          post :publicar
          post :despublicar
          get :estadisticas
        end
      end
    end
    
    # Laboratorios independientes
    resources :laboratorios, only: [:index, :show] do
      collection do
        get :disponibles
        get :completados
      end
    end
    
    # Quizzes independientes (vista general)
    resources :quizzes, only: [:index, :show] do
      resources :intentos, controller: 'intentos_quiz', only: [:create, :show, :update] do
        member do
          post :finalizar
          get :resultados
        end
      end
    end
    
    # Reportes
    resources :reportes, only: [:index, :show] do
      collection do
        get :descargar
      end
    end
    
    # Panel de administración
    namespace :admin do
      get '/', to: 'dashboard#index'
      resources :usuarios
      resources :cursos
      resources :laboratorios
      resources :configuracion, only: [:index, :update]
      resources :monitor, only: [:index, :show]
      resources :reportes, only: [:index, :show]
    end
  end
end