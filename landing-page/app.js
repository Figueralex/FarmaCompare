// 1. Datos simulados de medicamentos realistas e idénticos a las capturas reales (Venezuela)
const simulatedData = {
  atamel: [
    { 
      pharmacy: "Farmatina", 
      name: "ACETAMINOFEN 500MG X10TAB BLISTERDROTAFARMA", 
      price: 196.29, 
      discount: null, 
      originalPrice: null,
      type: "blister"
    },
    { 
      pharmacy: "Farmadon", 
      name: "Acetaminofén 500Mg X 10 Tabletas Calox", 
      price: 212.20, 
      discount: null, 
      originalPrice: null,
      type: "calox"
    },
    { 
      pharmacy: "Farmapaz", 
      name: "ACETAMINOFEN 500MG X 10 TAB (LAPROFF)", 
      price: 217.51, 
      discount: 11, 
      originalPrice: 244.03,
      type: "laproff"
    },
    { 
      pharmacy: "Farmadon", 
      name: "Acetaminofén 650Mg X 10 Tabletas Calox", 
      price: 228.12, 
      discount: null, 
      originalPrice: null,
      type: "calox"
    },
    { 
      pharmacy: "Farmadon", 
      name: "Acetaminofén 650mg x 10 Tabletas La Santé", 
      price: 228.12, 
      discount: null, 
      originalPrice: null,
      type: "lasante"
    },
    { 
      pharmacy: "Farmatodo", 
      name: "Acetaminofén 500 mg Genven Caja x 10 Tabletas", 
      price: 249.34, 
      discount: 16, 
      originalPrice: 297.08,
      type: "genven"
    },
    { 
      pharmacy: "Farmatina", 
      name: "ACETAMINOFEN 650MG X10TAB CALOX", 
      price: 265.25, 
      discount: null, 
      originalPrice: null,
      type: "calox"
    }
  ],
  losartan: [
    { 
      pharmacy: "Farmadon", 
      name: "Losartan Potásico 50mg x 30 Tabletas Calox", 
      price: 280.00, 
      discount: null, 
      originalPrice: null,
      type: "calox"
    },
    { 
      pharmacy: "Farmapaz", 
      name: "Losartan Potásico 50mg x 30 Tabletas (LAPROFF)", 
      price: 310.50, 
      discount: 10, 
      originalPrice: 345.00,
      type: "laproff"
    },
    { 
      pharmacy: "Farmatodo", 
      name: "Losartan Potásico 50mg Genven x 30 Tabletas", 
      price: 335.20, 
      discount: 15, 
      originalPrice: 394.35,
      type: "genven"
    },
    { 
      pharmacy: "Farmatina", 
      name: "LOSARTAN POTASICO 100MG X 30 TAB LA SANTE", 
      price: 389.00, 
      discount: null, 
      originalPrice: null,
      type: "lasante"
    }
  ],
  ibuprofeno: [
    { 
      pharmacy: "Farmapaz", 
      name: "Ibuprofeno 400mg x 10 Cápsulas (LAPROFF)", 
      price: 155.00, 
      discount: 12, 
      originalPrice: 176.14,
      type: "laproff"
    },
    { 
      pharmacy: "Farmatina", 
      name: "IBUPROFENO 400MG X10TAB CALOX", 
      price: 172.50, 
      discount: null, 
      originalPrice: null,
      type: "calox"
    },
    { 
      pharmacy: "Farmatodo", 
      name: "Ibuprofeno 400mg Genven Caja x 10 Tabletas", 
      price: 198.30, 
      discount: 8, 
      originalPrice: 215.54,
      type: "genven"
    },
    { 
      pharmacy: "Farmadon", 
      name: "Ibuprofeno 400mg x 10 Tabletas La Santé", 
      price: 212.00, 
      discount: null, 
      originalPrice: null,
      type: "lasante"
    }
  ]
};

// 2. Elementos del DOM
const searchInput = document.getElementById("sim-search-input");
const searchBtn = document.getElementById("sim-search-btn");
const suggestBtns = document.querySelectorAll(".suggest-btn");
const loader = document.getElementById("sim-loader");
const emptyState = document.getElementById("sim-empty");
const resultsContainer = document.getElementById("sim-results");
const resultsGrid = document.getElementById("sim-results-grid");
const resultsQuery = document.getElementById("results-query");
const resultsCountText = document.getElementById("results-count");
const savingsPercentText = document.getElementById("savings-percent");
const savingsBanner = document.getElementById("savings-banner");

// 3. Función principal de búsqueda
function performSearch(query) {
  const cleanQuery = query.trim().toLowerCase();
  if (!cleanQuery) return;

  // Ocultar estados y mostrar loader
  emptyState.classList.add("hidden");
  resultsContainer.classList.add("hidden");
  loader.classList.remove("hidden");

  // Simular latencia de red (tiempo de scraping real)
  setTimeout(() => {
    loader.classList.add("hidden");

    let results = [];
    
    // Obtener datos predefinidos o generar dinámicos
    if (simulatedData[cleanQuery]) {
      results = simulatedData[cleanQuery];
    } else {
      // Generar datos dinámicos al vuelo en Bolívares con bases reales
      const basePrice = Math.random() * (220.0 - 130.0) + 130.0;
      results = [
        { 
          pharmacy: "Farmatina", 
          name: `${query.toUpperCase()} 500MG X 10 TAB CALOX`, 
          price: parseFloat(basePrice.toFixed(2)),
          discount: null,
          originalPrice: null,
          type: "calox"
        },
        { 
          pharmacy: "Farmapaz", 
          name: `${query.toUpperCase()} 500MG X 10 TAB (LAPROFF)`, 
          price: parseFloat((basePrice * 1.08).toFixed(2)),
          discount: 10,
          originalPrice: parseFloat((basePrice * 1.2).toFixed(2)),
          type: "laproff"
        },
        { 
          pharmacy: "Farmadon", 
          name: `${query.toUpperCase()} 500mg x 10 Tabletas La Santé`, 
          price: parseFloat((basePrice * 1.15).toFixed(2)),
          discount: null,
          originalPrice: null,
          type: "lasante"
        },
        { 
          pharmacy: "Farmatodo", 
          name: `${query.toUpperCase()} 500 mg Genven Caja x 10 Tabletas`, 
          price: parseFloat((basePrice * 1.25).toFixed(2)),
          discount: 15,
          originalPrice: parseFloat((basePrice * 1.47).toFixed(2)),
          type: "genven"
        }
      ];
      
      // Ordenar por precio ascendente
      results.sort((a, b) => a.price - b.price);
    }

    // Renderizar resultados en pantalla
    renderResults(query, results);
  }, 1200); // 1.2 segundos simulando carga
}

// 4. Renderizar Tarjetas de Resultados Reales
function renderResults(query, results) {
  resultsGrid.innerHTML = "";
  resultsQuery.textContent = `"${query}"`;
  resultsCountText.textContent = `Se encontraron ${results.length} ofertas para:`;

  // Calcular el porcentaje de ahorro máximo
  const lowestPrice = results[0].price;
  const highestPrice = results[results.length - 1].price;
  const savingsPercent = Math.round(((highestPrice - lowestPrice) / highestPrice) * 100);

  // Generar HTML de las tarjetas
  results.forEach((item, index) => {
    const card = document.createElement("div");
    card.className = "sim-card";
    card.style.animationDelay = `${index * 0.08}s`; // Micro-animación en cascada

    // Diseñar SVG realista según el tipo de empaque
    let svgIcon = '';
    if (item.type === 'blister') {
      // Blister pack plateado
      svgIcon = `<svg viewBox="0 0 24 24" class="sim-product-icon" fill="none" stroke="#2563eb" stroke-width="1.5">
        <rect x="4" y="4" width="16" height="16" rx="2" fill="#e2e8f0"/>
        <circle cx="8" cy="8" r="2" fill="#cbd5e1" stroke="#94a3b8"/>
        <circle cx="16" cy="8" r="2" fill="#cbd5e1" stroke="#94a3b8"/>
        <circle cx="8" cy="16" r="2" fill="#cbd5e1" stroke="#94a3b8"/>
        <circle cx="16" cy="16" r="2" fill="#cbd5e1" stroke="#94a3b8"/>
      </svg>`;
    } else {
      // Caja de Calox/Genven/La Santé con franjas de colores reales
      let brandColor = '#c62828'; // Rojo Calox por defecto
      if (item.type === 'genven') brandColor = '#ef6c00'; // Naranja Genven
      if (item.type === 'lasante') brandColor = '#2e7d32'; // Verde La Santé
      if (item.type === 'laproff') brandColor = '#1565c0'; // Azul Laproff

      svgIcon = `<svg viewBox="0 0 24 24" class="sim-product-icon" fill="none" stroke="${brandColor}" stroke-width="1.5">
        <rect x="3" y="5" width="18" height="14" rx="2" fill="#ffffff" stroke="#cbd5e1" stroke-width="1"/>
        <rect x="3" y="11" width="18" height="4" fill="${brandColor}"/>
        <line x1="6" y1="8" x2="14" y2="8" stroke="#cbd5e1" stroke-width="2"/>
        <line x1="6" y1="17" x2="10" y2="17" stroke="#cbd5e1" stroke-width="2"/>
      </svg>`;
    }

    // Formatear precio
    const formattedPrice = item.price.toLocaleString("es-VE", { minimumFractionDigits: 2 });
    const formattedOriginal = item.originalPrice ? item.originalPrice.toLocaleString("es-VE", { minimumFractionDigits: 2 }) : null;

    card.innerHTML = `
      <div class="sim-img-container">
        ${svgIcon}
      </div>
      <div class="sim-card-info">
        <span class="sim-med-title">${item.name}</span>
        <span class="pharmacy-badge badge-${item.pharmacy.toLowerCase()}">${item.pharmacy}</span>
      </div>
      <div class="sim-card-prices">
        ${item.discount ? `
          <div class="sim-discount-group">
            <span class="sim-discount-tag">-${item.discount}%</span>
            <span class="sim-original-price">Bs. ${formattedOriginal}</span>
          </div>
        ` : ''}
        <span class="sim-real-price">Bs. ${formattedPrice}</span>
      </div>
    `;
    resultsGrid.appendChild(card);
  });

  // Mostrar pancarta de ahorro si es significativa
  if (savingsPercent > 0) {
    savingsPercentText.textContent = `${savingsPercent}%`;
    savingsBanner.classList.remove("hidden");
  } else {
    savingsBanner.classList.add("hidden");
  }

  // Mostrar el contenedor de resultados con efecto
  resultsContainer.classList.remove("hidden");
}

// 5. Configurar Listeners del Buscador
searchBtn.addEventListener("click", () => {
  performSearch(searchInput.value);
});

searchInput.addEventListener("keypress", (e) => {
  if (e.key === "Enter") {
    performSearch(searchInput.value);
  }
});

// Configurar sugerencias rápidas
suggestBtns.forEach(btn => {
  btn.addEventListener("click", () => {
    const query = btn.getAttribute("data-query");
    searchInput.value = query;
    performSearch(query);
  });
});

// 6. Sistema de Acordeón para Guía de Descargas
const accordionHeaders = document.querySelectorAll(".accordion-header");

accordionHeaders.forEach(header => {
  header.addEventListener("click", () => {
    const parent = header.parentElement;
    const isActive = parent.classList.contains("active");
    
    // Cerrar todos los acordeones
    document.querySelectorAll(".accordion-item").forEach(item => {
      item.classList.remove("active");
    });
    
    // Si no estaba activo, abrir el actual
    if (!isActive) {
      parent.classList.add("active");
    }
  });
});

// Abrir el primer elemento por defecto
document.querySelector(".accordion-item")?.classList.add("active");
