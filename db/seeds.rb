puts "Seeding database..."

# --- Demo User ---
user = User.find_or_create_by!(email: "demo@lidr.co") do |u|
  u.name = "Demo User"
  u.password = "password123"
end
puts "  User: #{user.email}"

# --- Helper to compute estimation totals from blocks data ---
def compute_totals(blocks_data)
  totals = { ho: 0, he: 0, hp: 0, co: 0, ce: 0, cp: 0 }
  blocks_data.each do |block|
    block[:tasks].each do |task|
      totals[:ho] += task[:hours_optimistic]
      totals[:he] += task[:hours_expected]
      totals[:hp] += task[:hours_pessimistic]
      totals[:co] += task[:hours_optimistic] * task[:rate]
      totals[:ce] += task[:hours_expected] * task[:rate]
      totals[:cp] += task[:hours_pessimistic] * task[:rate]
    end
  end
  totals
end

# --- Documents + ChunksBreakdowns ---
documents_data = [
  {
    title: "Plataforma SaaS de Gestión con IA",
    description: "Plataforma completa de gestión empresarial con módulos de facturación, CRM, y asistente IA integrado.",
    status: "completed", chunks_count: 22, budget: 85_000,
    technologies: ["Rails", "React", "PostgreSQL", "OpenAI"],
    duration: "16 semanas", created_at: "2026-02-10",
    breakdown: { project_overview: 4, scope_block: 6, line_item: 7, phase: 3, team_conditions: 2 }
  },
  {
    title: "E-commerce Marketplace B2B",
    description: "Marketplace B2B con catálogo multi-vendedor, sistema de pedidos, pasarela de pagos Stripe y panel de administración.",
    status: "completed", chunks_count: 18, budget: 62_000,
    technologies: ["Rails", "Vue.js", "PostgreSQL", "Stripe"],
    duration: "12 semanas", created_at: "2026-02-10",
    breakdown: { project_overview: 3, scope_block: 5, line_item: 6, phase: 2, team_conditions: 2 }
  },
  {
    title: "App Móvil de Delivery",
    description: "Aplicación móvil de delivery con tracking en tiempo real, gestión de pedidos y notificaciones push.",
    status: "processing", chunks_count: 0, budget: 45_000,
    technologies: ["React Native", "Node.js", "MongoDB"],
    duration: "10 semanas", created_at: "2026-02-10",
    breakdown: nil
  },
  {
    title: "CRM Interno con IA Conversacional",
    description: "CRM interno con chatbot IA conversacional para atención al cliente, pipeline de ventas y reporting automatizado.",
    status: "completed", chunks_count: 15, budget: 38_000,
    technologies: ["Django", "React", "PostgreSQL", "LangChain"],
    duration: "8 semanas", created_at: "2026-02-09",
    breakdown: { project_overview: 3, scope_block: 4, line_item: 4, phase: 2, team_conditions: 2 }
  },
  {
    title: "Dashboard Analytics BI",
    description: "Dashboard de Business Intelligence con visualización de datos en tiempo real.",
    status: "failed", chunks_count: 0, budget: 28_000,
    technologies: ["FastAPI", "React", "ClickHouse"],
    duration: "6 semanas", created_at: "2026-02-09",
    breakdown: nil
  },
  {
    title: "Fintech Payment Platform",
    description: "Plataforma de pagos fintech con procesamiento de transacciones en tiempo real y compliance PCI-DSS.",
    status: "completed", chunks_count: 25, budget: 120_000,
    technologies: ["Java", "React", "PostgreSQL", "Kafka"],
    duration: "20 semanas", created_at: "2026-02-08",
    breakdown: { project_overview: 5, scope_block: 7, line_item: 8, phase: 3, team_conditions: 2 }
  },
  {
    title: "Sistema de Reservas Online",
    description: "Sistema de reservas online con calendario interactivo, gestión de disponibilidad y pasarela de pagos.",
    status: "completed", chunks_count: 12, budget: 32_000,
    technologies: ["Rails", "React", "PostgreSQL"],
    duration: "8 semanas", created_at: "2026-02-07",
    breakdown: { project_overview: 2, scope_block: 3, line_item: 4, phase: 2, team_conditions: 1 }
  }
]

docs = documents_data.map do |data|
  breakdown_data = data.delete(:breakdown)
  doc = Document.find_or_create_by!(title: data[:title], user: user) do |d|
    d.assign_attributes(data.except(:title))
    d.ingested_at = data[:status] == "completed" ? data[:created_at] : nil
  end

  if breakdown_data && doc.chunks_breakdown.nil?
    doc.create_chunks_breakdown!(breakdown_data)
  end

  puts "  Document: #{doc.title} (#{doc.status})"
  doc
end

# --- Estimations with blocks, tasks, and references ---
estimations_data = [
  # doc-1: Plataforma SaaS de Gestión con IA
  {
    title: "Plataforma SaaS de Gestión con IA",
    description: "Plataforma completa de gestión empresarial con módulos de facturación, CRM, y asistente IA integrado.",
    status: "completed",
    global_rate: 80, currency: "EUR",
    confidence_score: 0.88, confidence_level: "high",
    technologies: ["Rails", "React", "PostgreSQL", "OpenAI"],
    created_at: "2026-02-10",
    blocks: [
      {
        name: "Diseño UX/UI y sistema de diseño", position: 0,
        tasks: [
          { name: "Investigación y benchmarking", hours_optimistic: 8, hours_expected: 12, hours_pessimistic: 16, rate: 80, position: 0 },
          { name: "Wireframes y prototipos", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 80, position: 1 },
          { name: "Design system y componentes", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 24, rate: 80, position: 2 }
        ]
      },
      {
        name: "Backend API y modelado de datos", position: 1,
        tasks: [
          { name: "Diseño de base de datos", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 20, rate: 80, position: 0 },
          { name: "API REST endpoints", hours_optimistic: 24, hours_expected: 32, hours_pessimistic: 44, rate: 80, position: 1 },
          { name: "Autenticación y permisos", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 85, position: 2 }
        ]
      },
      {
        name: "Módulo de facturación", position: 2,
        tasks: [
          { name: "CRUD facturas y presupuestos", hours_optimistic: 20, hours_expected: 28, hours_pessimistic: 36, rate: 80, position: 0 },
          { name: "Generación de PDFs", hours_optimistic: 8, hours_expected: 12, hours_pessimistic: 18, rate: 80, position: 1 },
          { name: "Integración pasarela de pagos", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 90, position: 2 }
        ]
      },
      {
        name: "Integración OpenAI y asistente IA", position: 3,
        tasks: [
          { name: "Configuración API OpenAI", hours_optimistic: 8, hours_expected: 12, hours_pessimistic: 16, rate: 90, position: 0 },
          { name: "Flujo conversacional y prompts", hours_optimistic: 20, hours_expected: 32, hours_pessimistic: 44, rate: 90, position: 1 },
          { name: "Automatización de tareas", hours_optimistic: 24, hours_expected: 36, hours_pessimistic: 48, rate: 90, position: 2 }
        ]
      },
      {
        name: "Testing y despliegue", position: 4,
        tasks: [
          { name: "Tests unitarios y de integración", hours_optimistic: 20, hours_expected: 28, hours_pessimistic: 40, rate: 75, position: 0 },
          { name: "CI/CD y despliegue", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 24, rate: 75, position: 1 }
        ]
      }
    ],
    references: [
      { title: "ERP Cloud para PYMES", similarity_score: 0.91, cost: 92_000, technologies: ["Rails", "React"] },
      { title: "SaaS de RRHH con IA", similarity_score: 0.84, cost: 78_000, technologies: ["Django", "React"] },
      { title: "Plataforma de gestión documental", similarity_score: 0.79, cost: 65_000, technologies: ["Rails", "Vue.js"] }
    ]
  },
  # doc-2: E-commerce Marketplace B2B
  {
    title: "E-commerce Marketplace B2B",
    description: "Marketplace B2B con catálogo multi-vendedor, sistema de pedidos, pasarela de pagos Stripe y panel de administración.",
    status: "completed",
    global_rate: 75, currency: "EUR",
    confidence_score: 0.82, confidence_level: "high",
    technologies: ["Rails", "Vue.js", "PostgreSQL", "Stripe"],
    created_at: "2026-02-10",
    blocks: [
      {
        name: "Catálogo y gestión de productos", position: 0,
        tasks: [
          { name: "Modelo de datos multi-vendedor", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 24, rate: 75, position: 0 },
          { name: "Búsqueda y filtros", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 75, position: 1 },
          { name: "Gestión de inventario", hours_optimistic: 12, hours_expected: 18, hours_pessimistic: 24, rate: 75, position: 2 }
        ]
      },
      {
        name: "Sistema de pedidos y carrito", position: 1,
        tasks: [
          { name: "Carrito de compras", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 24, rate: 75, position: 0 },
          { name: "Flujo de checkout", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 80, position: 1 },
          { name: "Gestión de pedidos", hours_optimistic: 12, hours_expected: 18, hours_pessimistic: 24, rate: 75, position: 2 }
        ]
      },
      {
        name: "Integración Stripe", position: 2,
        tasks: [
          { name: "Pagos y suscripciones", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 36, rate: 85, position: 0 },
          { name: "Webhooks y reconciliación", hours_optimistic: 12, hours_expected: 20, hours_pessimistic: 28, rate: 85, position: 1 }
        ]
      },
      {
        name: "Panel multi-vendedor", position: 3,
        tasks: [
          { name: "Dashboard vendedor", hours_optimistic: 20, hours_expected: 28, hours_pessimistic: 40, rate: 75, position: 0 },
          { name: "Reporting de ventas", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 75, position: 1 }
        ]
      }
    ],
    references: [
      { title: "Marketplace de servicios freelance", similarity_score: 0.87, cost: 58_000, technologies: ["Rails", "React"] },
      { title: "E-commerce D2C", similarity_score: 0.81, cost: 45_000, technologies: ["Next.js", "Stripe"] }
    ]
  },
  # doc-3: App Móvil de Delivery (processing — empty blocks)
  {
    title: "App Móvil de Delivery",
    description: "Aplicación móvil de delivery con tracking en tiempo real, gestión de pedidos y notificaciones push.",
    status: "processing",
    global_rate: 70, currency: "EUR",
    confidence_score: 0.45, confidence_level: "low",
    technologies: ["React Native", "Node.js", "MongoDB"],
    created_at: "2026-02-10",
    blocks: [],
    references: []
  },
  # doc-4: CRM Interno con IA Conversacional
  {
    title: "CRM Interno con IA Conversacional",
    description: "CRM interno con chatbot IA conversacional para atención al cliente, pipeline de ventas y reporting automatizado.",
    status: "completed",
    global_rate: 80, currency: "EUR",
    confidence_score: 0.76, confidence_level: "high",
    technologies: ["Django", "React", "PostgreSQL", "LangChain"],
    created_at: "2026-02-09",
    blocks: [
      {
        name: "Pipeline de ventas", position: 0,
        tasks: [
          { name: "Kanban de oportunidades", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 80, position: 0 },
          { name: "Gestión de leads", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 24, rate: 80, position: 1 }
        ]
      },
      {
        name: "Chatbot IA con LangChain", position: 1,
        tasks: [
          { name: "Integración LangChain", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 36, rate: 90, position: 0 },
          { name: "Entrenamiento y fine-tuning", hours_optimistic: 12, hours_expected: 20, hours_pessimistic: 28, rate: 90, position: 1 },
          { name: "Widget de chat en UI", hours_optimistic: 8, hours_expected: 12, hours_pessimistic: 16, rate: 80, position: 2 }
        ]
      },
      {
        name: "Reporting y dashboards", position: 2,
        tasks: [
          { name: "Gráficos y métricas", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 80, position: 0 },
          { name: "Exportación de informes", hours_optimistic: 8, hours_expected: 12, hours_pessimistic: 16, rate: 75, position: 1 }
        ]
      }
    ],
    references: [
      { title: "CRM SaaS B2B", similarity_score: 0.89, cost: 42_000, technologies: ["Django", "React"] },
      { title: "Plataforma de soporte con IA", similarity_score: 0.82, cost: 35_000, technologies: ["Node.js", "React"] }
    ]
  },
  # doc-5: Dashboard Analytics BI (failed — empty blocks)
  {
    title: "Dashboard Analytics BI",
    description: "Dashboard de Business Intelligence con visualización de datos en tiempo real.",
    status: "failed",
    global_rate: 80, currency: "EUR",
    confidence_score: 0.0, confidence_level: "none",
    technologies: ["FastAPI", "React", "ClickHouse"],
    created_at: "2026-02-09",
    blocks: [],
    references: []
  },
  # doc-6: Fintech Payment Platform
  {
    title: "Fintech Payment Platform",
    description: "Plataforma de pagos fintech con procesamiento de transacciones en tiempo real y compliance PCI-DSS.",
    status: "completed",
    global_rate: 95, currency: "EUR",
    confidence_score: 0.72, confidence_level: "high",
    technologies: ["Java", "React", "PostgreSQL", "Kafka"],
    created_at: "2026-02-08",
    blocks: [
      {
        name: "Core de procesamiento de pagos", position: 0,
        tasks: [
          { name: "Motor de transacciones", hours_optimistic: 40, hours_expected: 56, hours_pessimistic: 72, rate: 100, position: 0 },
          { name: "Sistema de colas y eventos", hours_optimistic: 24, hours_expected: 32, hours_pessimistic: 44, rate: 95, position: 1 }
        ]
      },
      {
        name: "Compliance y seguridad PCI-DSS", position: 1,
        tasks: [
          { name: "Auditoría y certificación", hours_optimistic: 32, hours_expected: 44, hours_pessimistic: 60, rate: 100, position: 0 },
          { name: "Encriptación y tokenización", hours_optimistic: 24, hours_expected: 36, hours_pessimistic: 48, rate: 100, position: 1 }
        ]
      },
      {
        name: "Sistema de reconciliación", position: 2,
        tasks: [
          { name: "Reconciliación bancaria", hours_optimistic: 20, hours_expected: 32, hours_pessimistic: 44, rate: 95, position: 0 },
          { name: "Reportes financieros", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 90, position: 1 }
        ]
      },
      {
        name: "Dashboard de operaciones", position: 3,
        tasks: [
          { name: "Monitorización en tiempo real", hours_optimistic: 20, hours_expected: 28, hours_pessimistic: 40, rate: 90, position: 0 },
          { name: "Alertas y notificaciones", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 24, rate: 85, position: 1 }
        ]
      }
    ],
    references: [
      { title: "Pasarela de pagos B2B", similarity_score: 0.85, cost: 110_000, technologies: ["Java", "PostgreSQL"] },
      { title: "Neobank MVP", similarity_score: 0.78, cost: 135_000, technologies: ["Go", "React", "Kafka"] },
      { title: "Sistema de facturación SaaS", similarity_score: 0.71, cost: 95_000, technologies: ["Java", "React"] }
    ]
  },
  # doc-7: Sistema de Reservas Online
  {
    title: "Sistema de Reservas Online",
    description: "Sistema de reservas online con calendario interactivo, gestión de disponibilidad y pasarela de pagos.",
    status: "completed",
    global_rate: 70, currency: "EUR",
    confidence_score: 0.85, confidence_level: "high",
    technologies: ["Rails", "React", "PostgreSQL"],
    created_at: "2026-02-07",
    blocks: [
      {
        name: "Calendario y disponibilidad", position: 0,
        tasks: [
          { name: "Componente de calendario", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 70, position: 0 },
          { name: "Motor de disponibilidad", hours_optimistic: 12, hours_expected: 20, hours_pessimistic: 28, rate: 70, position: 1 }
        ]
      },
      {
        name: "Motor de reservas", position: 1,
        tasks: [
          { name: "Flujo de reserva", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 70, position: 0 },
          { name: "Confirmaciones y cancelaciones", hours_optimistic: 8, hours_expected: 12, hours_pessimistic: 20, rate: 70, position: 1 }
        ]
      },
      {
        name: "Notificaciones y pagos", position: 2,
        tasks: [
          { name: "Email y SMS", hours_optimistic: 12, hours_expected: 16, hours_pessimistic: 24, rate: 70, position: 0 },
          { name: "Pasarela de pagos", hours_optimistic: 16, hours_expected: 24, hours_pessimistic: 32, rate: 75, position: 1 }
        ]
      }
    ],
    references: [
      { title: "Booking de clínicas médicas", similarity_score: 0.92, cost: 30_000, technologies: ["Rails", "React"] },
      { title: "Reservas de coworking", similarity_score: 0.86, cost: 28_000, technologies: ["Django", "Vue.js"] }
    ]
  }
]

estimations_data.each do |est_data|
  blocks_data = est_data.delete(:blocks)
  refs_data = est_data.delete(:references)

  # Compute totals from blocks
  totals = compute_totals(blocks_data)
  est_data[:total_hours_optimistic] = totals[:ho]
  est_data[:total_hours_expected] = totals[:he]
  est_data[:total_hours_pessimistic] = totals[:hp]
  est_data[:total_cost_optimistic] = totals[:co]
  est_data[:total_cost_expected] = totals[:ce]
  est_data[:total_cost_pessimistic] = totals[:cp]

  estimation = Estimation.find_or_create_by!(title: est_data[:title], user: user) do |e|
    e.assign_attributes(est_data.except(:title))
  end

  blocks_data.each do |block_data|
    tasks_data = block_data.delete(:tasks)
    block = estimation.functional_blocks.find_or_create_by!(name: block_data[:name]) do |b|
      b.position = block_data[:position]
    end

    tasks_data.each do |task_data|
      block.tasks.find_or_create_by!(name: task_data[:name]) do |t|
        t.assign_attributes(task_data.except(:name))
      end
    end
  end

  refs_data.each do |ref_data|
    estimation.references.find_or_create_by!(title: ref_data[:title]) do |r|
      r.assign_attributes(ref_data.except(:title))
    end
  end

  puts "  Estimation: #{estimation.title} (#{estimation.status}) — #{estimation.functional_blocks.count} blocks"
end

puts "\nSeed complete!"
puts "  Users: #{User.count}"
puts "  Documents: #{Document.count}"
puts "  ChunksBreakdowns: #{ChunksBreakdown.count}"
puts "  Estimations: #{Estimation.count}"
puts "  FunctionalBlocks: #{FunctionalBlock.count}"
puts "  Tasks: #{Task.count}"
puts "  References: #{Reference.count}"
