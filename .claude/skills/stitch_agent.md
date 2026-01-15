# Stitch Agent - Ultra Modern UI/UX Design System

## Purpose
Apply ultra modern design patterns and ExamsGraph design system to web applications using advanced CSS techniques, animations, and interactive components.

## Core Design Principles

### 1. Glass Morphism
- Semi-transparent backgrounds with blur effects
- Soft borders and subtle shadows
- Light/dark mode adaptive

### 2. 3D Transform Effects
- Card flip animations
- Perspective transforms
- Interactive hover states

### 3. Animated Backgrounds
- Gradient mesh animations
- Floating particles and blobs
- Grid patterns and noise textures

### 4. Modern Typography
- Variable fonts
- Material Icons integration
- Responsive text sizing

## Component Library

### Glass Card Component
```erb
<div class="glass-card">
  <!-- Content -->
</div>
```

### 3D Flip Card Component
```erb
<div class="card-3d" data-controller="flip-card">
  <div class="card-face card-front">
    <!-- Front content -->
  </div>
  <div class="card-face card-back">
    <!-- Back content -->
  </div>
</div>
```

### Animated Background
```erb
<%= render 'shared/animated_background' %>
```

## Color Palette

### Primary Colors
- Primary Blue: #137fec
- Secondary Purple: #764ba2
- Accent Pink: #f093fb
- Gradient Start: #667eea
- Gradient End: #4facfe

### Supporting Colors
- Success: #10b981
- Warning: #f59e0b
- Error: #ef4444
- Info: #3b82f6

## Animation Presets

### Blob Animation
```css
@keyframes blob {
  0%, 100% { transform: translate(0, 0) scale(1); }
  25% { transform: translate(20px, -50px) scale(1.1); }
  50% { transform: translate(-20px, 20px) scale(1); }
  75% { transform: translate(-50px, -10px) scale(0.9); }
}
```

### Shimmer Effect
```css
@keyframes shimmer {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(100%); }
}
```

### Float Animation
```css
@keyframes float {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-20px); }
}
```

## Implementation Guidelines

### Rails Integration
1. Create partials in `app/views/shared/`
2. Use Stimulus controllers for interactions
3. Style with Tailwind + custom CSS
4. Support Turbo navigation

### Performance Optimization
- Use CSS containment for animations
- Implement reduced motion media queries
- Lazy load heavy components
- Optimize asset pipeline

### Accessibility
- Maintain WCAG 2.1 AA compliance
- Provide keyboard navigation
- Include ARIA labels
- Support screen readers

## Usage Examples

### Apply to Study Set Page
```ruby
# In view file
<%= render 'shared/animated_background' %>

<div class="grid grid-cols-1 md:grid-cols-3 gap-6">
  <%= render 'shared/3d_flip_card',
    title: "모의고사",
    description: "실제 시험 환경 체험",
    icon: "school",
    badge: "EXAM"
  %>

  <%= render 'shared/glass_card',
    title: "연습 모드",
    description: "시간 제한 없이 학습",
    icon: "fitness_center",
    badge: "PRACTICE"
  %>
</div>
```

### Responsive Design
```css
/* Mobile First Approach */
.component {
  /* Mobile styles */
}

@media (min-width: 768px) {
  .component {
    /* Tablet styles */
  }
}

@media (min-width: 1024px) {
  .component {
    /* Desktop styles */
  }
}
```

## File Structure
```
app/
├── assets/
│   └── stylesheets/
│       ├── ultra_modern.css
│       └── application.css
├── views/
│   └── shared/
│       ├── _animated_background.html.erb
│       ├── _glass_card.html.erb
│       └── _3d_flip_card.html.erb
└── javascript/
    └── controllers/
        ├── flip_card_controller.js
        └── spotlight_controller.js
```

## Testing Checklist
- [ ] Cross-browser compatibility
- [ ] Mobile responsiveness
- [ ] Animation performance
- [ ] Dark mode support
- [ ] Accessibility compliance
- [ ] Loading performance
- [ ] Turbo compatibility

## Resources
- ExamsGraph Design System
- Material Design Icons
- Tailwind CSS Documentation
- Stimulus Controllers Guide