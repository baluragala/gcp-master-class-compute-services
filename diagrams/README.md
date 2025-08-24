# Architecture Diagrams

This directory contains Mermaid diagram files that visualize the high-availability GCP infrastructure architecture.

## 📊 Available Diagrams

### 1. Architecture Overview (`architecture-overview.mmd`)
- **Type**: Flowchart diagram
- **Purpose**: Shows the complete infrastructure architecture and component relationships
- **Includes**:
  - Traffic flow from users to backend instances
  - All GCP resources and their connections
  - Network architecture (VPC, subnet, firewall rules)
  - Security components (service accounts, firewall rules)
  - Load balancing and auto-healing mechanisms

### 2. Request Flow Sequence (`request-flow-sequence.mmd`)
- **Type**: Sequence diagram
- **Purpose**: Illustrates the step-by-step request processing flow
- **Includes**:
  - Health check monitoring process
  - User request routing through load balancer
  - Load balancing decisions and instance selection
  - Auto-healing scenario with instance replacement
  - Zero-downtime failover demonstration

## 🔧 How to Use These Diagrams

### Online Rendering
1. **Mermaid Live Editor**: Copy the content and paste it into [mermaid.live](https://mermaid.live)
2. **GitHub**: These `.mmd` files will render automatically in GitHub when viewed
3. **GitLab**: Native Mermaid support in GitLab markdown

### Local Rendering
```bash
# Install Mermaid CLI
npm install -g @mermaid-js/mermaid-cli

# Generate PNG images
mmdc -i architecture-overview.mmd -o architecture-overview.png
mmdc -i request-flow-sequence.mmd -o request-flow-sequence.png

# Generate SVG images
mmdc -i architecture-overview.mmd -o architecture-overview.svg
mmdc -i request-flow-sequence.mmd -o request-flow-sequence.svg
```

### Integration in Documentation
You can embed these diagrams in markdown files:

```markdown
## Architecture Overview
```mermaid
{{< include "diagrams/architecture-overview.mmd" >}}
```

## Infrastructure Components
```mermaid
{{< include "diagrams/request-flow-sequence.mmd" >}}
```
```

### VS Code Integration
Install the "Mermaid Markdown Syntax Highlighting" extension to view diagrams directly in VS Code.

## 🎨 Diagram Features

### Architecture Overview Diagram
- **Color Coding**: Different components use distinct colors for easy identification
- **Grouping**: Related components are grouped in subgraphs
- **Flow Arrows**: Show data flow and relationships
- **Styling**: Professional appearance with consistent formatting

### Request Flow Sequence Diagram
- **Participants**: All major system components
- **Interactions**: Step-by-step request processing
- **Alternatives**: Different routing scenarios
- **Notes**: Explanatory comments for complex operations

## 🔄 Updating Diagrams

When infrastructure changes are made:

1. Update the corresponding `.mmd` file
2. Test the diagram syntax at [mermaid.live](https://mermaid.live)
3. Commit the changes to version control
4. Regenerate images if using static image files

## 📚 Mermaid Syntax Reference

- [Mermaid Documentation](https://mermaid-js.github.io/mermaid/)
- [Flowchart Syntax](https://mermaid-js.github.io/mermaid/#/flowchart)
- [Sequence Diagram Syntax](https://mermaid-js.github.io/mermaid/#/sequenceDiagram)

## 🎯 Use Cases

These diagrams are useful for:
- **Documentation**: Technical documentation and architecture reviews
- **Presentations**: Stakeholder presentations and team meetings
- **Onboarding**: New team member orientation
- **Troubleshooting**: Understanding system behavior during issues
- **Planning**: Infrastructure changes and scaling decisions
