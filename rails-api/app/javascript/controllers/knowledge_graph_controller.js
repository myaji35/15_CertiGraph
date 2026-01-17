import { Controller } from "@hotwired/stimulus"

// Knowledge Graph 3D Visualization Controller
export default class extends Controller {
  static values = {
    studyMaterialId: Number,
    apiEndpoint: String
  }

  connect() {
    console.log("Knowledge Graph Controller connected")
    this.setupEventListeners()
  }

  setupEventListeners() {
    // Listen for visualization button clicks
    document.querySelectorAll('.kg-visualize-btn, .kg-link').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.preventDefault()
        const studyMaterialId = btn.dataset.studyMaterialId || this.studyMaterialIdValue
        this.openVisualization(studyMaterialId)
      })
    })

    // Close modal listener
    const closeBtn = document.getElementById('close-kg-modal')
    if (closeBtn) {
      closeBtn.addEventListener('click', () => this.closeModal())
    }
  }

  async openVisualization(studyMaterialId) {
    const modal = document.getElementById('kg-modal')
    if (!modal) return

    modal.classList.remove('hidden')

    // Load graph data
    await this.loadGraphData(studyMaterialId)
  }

  closeModal() {
    const modal = document.getElementById('kg-modal')
    if (modal) {
      modal.classList.add('hidden')
    }
  }

  async loadGraphData(studyMaterialId) {
    try {
      const response = await fetch(`/api/v1/knowledge_graphs/${studyMaterialId}/nodes`)
      const data = await response.json()

      if (data.success) {
        this.renderGraph(data.nodes)
      } else {
        console.error('Failed to load graph data')
      }
    } catch (error) {
      console.error('Error loading graph:', error)
    }
  }

  renderGraph(nodes) {
    const container = document.getElementById('knowledge-graph-container')
    if (!container) return

    const masteredCount = nodes.filter(n => n.mastery_status === 'mastered').length
    const learningCount = nodes.filter(n => n.mastery_status === 'learning').length
    const weakCount = nodes.filter(n => n.mastery_status === 'weak').length
    const untestedCount = nodes.filter(n => n.mastery_status === 'untested').length

    // Simple 2D visualization (placeholder for Three.js)
    container.innerHTML = `
      <div class="w-full h-full flex flex-col">
        <div class="mb-4 flex justify-between items-center">
          <div class="flex space-x-4">
            <div class="flex items-center space-x-2">
              <div class="w-4 h-4 bg-green-500 rounded-full"></div>
              <span class="text-sm">숙달 (${masteredCount})</span>
            </div>
            <div class="flex items-center space-x-2">
              <div class="w-4 h-4 bg-yellow-500 rounded-full"></div>
              <span class="text-sm">학습중 (${learningCount})</span>
            </div>
            <div class="flex items-center space-x-2">
              <div class="w-4 h-4 bg-red-500 rounded-full"></div>
              <span class="text-sm">취약 (${weakCount})</span>
            </div>
            <div class="flex items-center space-x-2">
              <div class="w-4 h-4 bg-gray-400 rounded-full"></div>
              <span class="text-sm">미응시 (${untestedCount})</span>
            </div>
          </div>
          <div class="text-sm text-gray-600">총 ${nodes.length}개 개념</div>
        </div>
        <div class="flex-1 overflow-y-auto">
          <div class="grid grid-cols-3 gap-4">
            ${nodes.map(node => this.renderNode(node)).join('')}
          </div>
        </div>
      </div>
    `

    // Add click listeners to nodes
    container.querySelectorAll('.kg-node').forEach(nodeEl => {
      nodeEl.addEventListener('click', (e) => {
        const nodeId = e.currentTarget.dataset.nodeId
        this.showNodeDetail(nodes.find(n => n.id == nodeId))
      })
    })
  }

  renderNode(node) {
    const colorClass = {
      'mastered': 'bg-green-100 border-green-400 hover:bg-green-200',
      'learning': 'bg-yellow-100 border-yellow-400 hover:bg-yellow-200',
      'weak': 'bg-red-100 border-red-400 hover:bg-red-200',
      'untested': 'bg-gray-100 border-gray-400 hover:bg-gray-200'
    }[node.mastery_status] || 'bg-gray-100 border-gray-400'

    return `
      <div class="kg-node border-2 ${colorClass} rounded-lg p-4 cursor-pointer transition" data-node-id="${node.id}">
        <div class="font-semibold text-sm mb-1">${node.name}</div>
        <div class="text-xs text-gray-600">${node.level}</div>
        <div class="mt-2 flex justify-between text-xs">
          <span>숙달도: ${node.mastery_percentage}%</span>
          <span>문제: ${node.question_count}</span>
        </div>
        <div class="mt-1 w-full bg-gray-200 rounded-full h-1.5">
          <div class="bg-blue-600 h-1.5 rounded-full" style="width: ${node.mastery_percentage}%"></div>
        </div>
      </div>
    `
  }

  showNodeDetail(node) {
    alert(`개념: ${node.name}\n숙달도: ${node.mastery_percentage}%\n정답: ${node.correct_count}, 오답: ${node.incorrect_count}\n난이도: ${node.difficulty}/5\n중요도: ${node.importance}/10`)
  }
}
