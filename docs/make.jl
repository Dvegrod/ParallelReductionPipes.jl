using ParallelReductionPipes
using Documenter
using DocExtensions
using DocExtensions.DocumenterExtensions

const DOCSRC      = joinpath(@__DIR__, "src")
const DOCASSETS   = joinpath(DOCSRC, "assets")
const EXAMPLEROOT = joinpath(@__DIR__, "..", "examples")

DocMeta.setdocmeta!(ParallelReductionPipes, :DocTestSetup, :(using ParallelReductionPipes); recursive=true)


@info "Copy examples folder to assets..."
mkpath(DOCASSETS)
cp(EXAMPLEROOT, joinpath(DOCASSETS, "examples"); force=true)


@info "Preprocessing .MD-files..."
include("reflinks.jl")
MarkdownExtensions.expand_reflinks(reflinks; rootdir=DOCSRC)


@info "Building documentation website using Documenter.jl..."
makedocs(;
    modules  = [ParallelReductionPipes],
    authors  = "Daniel Sergio Vega Rodriguez, Samuel Omlin, and contributors",
    repo     = "https://github.com/JuliaParallel/ParallelReductionPipes.jl/blob/{commit}{path}#{line}",
    sitename = "ParallelReductionPipes.jl",
    format   = Documenter.HTML(;
        prettyurls       = true, #get(ENV, "CI", "false") == "true",
        canonical        = "https://JuliaParallel.github.io/ParallelReductionPipes.jl",
        collapselevel    = 1,
        sidebar_sitename = true,
        edit_link        = "main",
        #assets           = [asset("https://img.shields.io/github/stars/JuliaParallel/ParallelReductionPipes.jl.svg", class = :ico)],
        #warn_outdated    = true,
    ),
    pages   = [
        "Introduction"  => "index.md",
        "Usage"         => "usage.md",
        "Examples"      => [hide("..." => "examples.md"),
                            "examples/memcopyCellArray3D.md",
                            "examples/memcopyCellArray3D_ParallelStencil.md",
                           ],
        "API reference" => "api.md",
    ],
)


@info "Deploying docs..."
deploydocs(;
    repo         = "github.com/JuliaParallel/ParallelReductionPipes.jl",
    push_preview = true,
    devbranch    = "main",
)
