#!/usr/bin/env python3
"""
Convert embedding model to CoreML format for use in Serena.
Downloads a sentence transformer model and converts it to CoreML.
"""

import os
import sys
import coremltools as ct
import torch
from sentence_transformers import SentenceTransformer
from pathlib import Path

# Force CPU usage to avoid MPS issues
os.environ['PYTORCH_ENABLE_MPS_FALLBACK'] = '1'
torch.set_default_device('cpu')

def convert_embeddings_to_coreml():
    """Download and convert sentence transformer model to CoreML."""

    print("🚀 Starting embedding model conversion...")

    # Model configuration
    model_name = "sentence-transformers/all-MiniLM-L6-v2"  # Fast, efficient embedding model
    output_dir = Path("Models")
    output_dir.mkdir(exist_ok=True)

    output_path = output_dir / "embedding_model.mlpackage"

    print(f"📥 Downloading model: {model_name}")
    print("   This may take a few minutes...")

    # Load the sentence transformer model on CPU
    model = SentenceTransformer(model_name, device='cpu')

    print("✅ Model downloaded successfully")
    print("🔄 Converting to CoreML format...")

    # Get the underlying transformer model
    transformer = model[0].auto_model
    tokenizer = model.tokenizer

    # Ensure model is on CPU and in eval mode
    transformer = transformer.cpu()
    transformer.eval()

    # Create example input for tracing
    example_text = "This is an example sentence for model tracing."
    inputs = tokenizer(
        example_text,
        padding="max_length",
        max_length=128,
        truncation=True,
        return_tensors="pt"
    )

    # Ensure inputs are on CPU
    input_ids = inputs['input_ids'].cpu()
    attention_mask = inputs['attention_mask'].cpu()

    # Create a wrapper that returns only the embeddings
    class EmbeddingModelWrapper(torch.nn.Module):
        def __init__(self, model):
            super().__init__()
            self.model = model

        def forward(self, input_ids, attention_mask):
            outputs = self.model(input_ids=input_ids, attention_mask=attention_mask)
            # Return only the last hidden state (embeddings)
            return outputs.last_hidden_state

    wrapped_model = EmbeddingModelWrapper(transformer)
    wrapped_model.eval()

    # Trace the model
    print("   Tracing model with example input...")
    with torch.no_grad():
        traced_model = torch.jit.trace(
            wrapped_model,
            (input_ids, attention_mask)
        )

    # Convert to CoreML
    print("   Converting to CoreML (this may take several minutes)...")

    mlmodel = ct.convert(
        traced_model,
        inputs=[
            ct.TensorType(name="input_ids", shape=(1, 128), dtype=int),
            ct.TensorType(name="attention_mask", shape=(1, 128), dtype=int)
        ],
        minimum_deployment_target=ct.target.macOS13,
        convert_to="mlprogram"
    )

    # Save the model
    print(f"💾 Saving model to: {output_path}")
    mlmodel.save(str(output_path))

    print("✅ Conversion complete!")
    print(f"📁 Model saved to: {output_path}")
    print(f"\n📊 Model info:")
    print(f"   - Model: {model_name}")
    print(f"   - Max sequence length: 128 tokens")
    print(f"   - Embedding dimension: 384")
    print(f"\nNext step: Compile with CoreML compiler:")
    print(f"xcrun coremlcompiler compile {output_path} Models/")
    print(f"This will create: Models/embedding_model.mlmodelc")

    return output_path

if __name__ == "__main__":
    try:
        convert_embeddings_to_coreml()
    except Exception as e:
        print(f"❌ Error: {e}", file=sys.stderr)
        sys.exit(1)
