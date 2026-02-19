import os
import re
import sys
import networkx as nx
import matplotlib.pyplot as plt

def build_graph_from_vault(vault_path):
    """
    Scans a directory for markdown files and builds a directed graph
    based on wikilinks.
    """
    link_pattern = re.compile(r'\[\[(.*?)\]\]')
    G = nx.DiGraph()
    
    md_files = []
    for root, _, files in os.walk(vault_path):
        for file in files:
            if file.endswith('.md'):
                md_files.append(os.path.join(root, file))

    # First pass: add all markdown files as nodes
    for file_path in md_files:
        G.add_node(os.path.basename(file_path))

    # Second pass: find links and add edges
    for file_path in md_files:
        source_node = os.path.basename(file_path)
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
                matches = link_pattern.findall(content)
                for match in matches:
                    target_node = match.split('|')[0].strip()
                    if not '.' in os.path.basename(target_node):
                        target_node += ".md"
                    
                    if G.has_node(target_node):
                        G.add_edge(source_node, target_node)
                    else:
                        print(f"  - Warning: Link to non-existent node '{target_node}' in file '{source_node}'. Ignoring.", file=sys.stderr)
        except Exception as e:
            print(f"Error reading file {file_path}: {e}", file=sys.stderr)
            
    return G

def visualize_graph(G, output_path):
    """
    Creates and saves a visualization of the graph.
    """
    if G.number_of_nodes() == 0:
        print("Graph is empty, nothing to visualize.")
        return

    print("\n--- Starting Visualization ---")
    plt.figure(figsize=(16, 16))
    
    # Use a layout that spreads nodes out
    pos = nx.spring_layout(G, k=0.8, iterations=50, seed=42)
    
    nx.draw(G, pos, 
            with_labels=True, 
            node_size=3500, 
            node_color="#a0c4ff", 
            font_size=8, 
            font_weight="bold",
            width=1.5,
            edge_color="grey",
            arrows=True,
            arrowsize=20)
            
    plt.title("Карта Памяти (Memory Graph)", size=20)
    
    try:
        plt.savefig(output_path, format="PNG", dpi=150)
        print(f"Graph saved to: {output_path}")
    except Exception as e:
        print(f"Error saving graph image: {e}", file=sys.stderr)


if __name__ == "__main__":
    # Define paths
    vault_path = "/Users/Адам_Memory/"
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_image_path = os.path.join(script_dir, "memory_graph.png")

    # Check vault existence
    if not os.path.isdir(vault_path):
        print(f"Error: Vault directory not found at {vault_path}", file=sys.stderr)
        sys.exit(1)
        
    # Build graph
    print(f"Building graph from vault at: {vault_path}\n")
    graph = build_graph_from_vault(vault_path)
    
    # Print stats
    print("\n--- Graph Creation Complete ---")
    print(f"Graph has {graph.number_of_nodes()} nodes (files).")
    print(f"Graph has {graph.number_of_edges()} edges (links).")

    # Visualize graph
    visualize_graph(graph, output_image_path)
    
    print("\n--- Process Finished ---")
