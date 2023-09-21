function Get-CostPerModel {
    param(
        [string] $Name,
        [string] $Model,
        [int] $Total
    )

    if ($Total -eq 0) { return 0.0 } 
    else {
        $cost = 0.0

        switch ($Model.ToLower()) {
            "gpt-35-turbo" { 
                switch ($Name) {
                    "GeneratedTokens" { $cost = 0.002 * $Total / 1000 }
                    "ProcessedPromptTokens" { $cost = 0.0015 * $Total / 1000 }
                }
            }
            "gpt-35-turbo-16k" { 
                switch ($Name) {
                    "GeneratedTokens" { $cost = 0.004 * $Total / 1000 }
                    "ProcessedPromptTokens" { $cost = 0.003 * $Total / 1000 }
                }
            }
            "gpt-4" { 
                switch ($Name) {
                    "GeneratedTokens" { $cost = 0.06 * $Total / 1000 }
                    "ProcessedPromptTokens" { $cost = 0.03 * $Total / 1000 }
                }
            }
            "gpt-4-32k" { 
                switch ($Name) {
                    "GeneratedTokens" { $cost = 0.12 * $Total / 1000 }
                    "ProcessedPromptTokens" { $cost = 0.06 * $Total / 1000 }
                }
            }
            "dalle" { 
                if ($Name -eq "TokenTransaction") {
                    $cost = 2.00 * $Total / 100 
                }           
            }
            default { 
                if ($Model.ToLower().Contains("embedding") -and $Name -eq "TokenTransaction") {
                    $cost = 0.0001 * $Total / 1000
                }
                elseif ($Name -eq "TokenTransaction") {
                    # Most likely GPT-3.5-turbo or legacy
                    $cost = 0.002 * $Total / 1000
                }
            }
        }    
        
        return $cost
    }
}

Export-ModuleMember -Function Get-CostPerModel

<# 
Azure Open AI Global pricing as of 2023-09-20

price   per skuName
0.0001	1k  Embeddings-Ada
0	    1k  Free
0.002   1k  GPT-3.5-turbo
0.002   1k  GPT-35-turbo-4k-Completion
0.0015	1k  GPT-35-turbo-4k-Prompt
0.004   1k  GPT-35-turbo-16k-Completion
0.003   1k  GPT-35-turbo-16k-Prompt
0.06    1k  GPT4-8K-Completion
0.03    1k  GPT4-8K-Prompt
0.12    1k  GPT4-32K-Completion
0.06    1k  GPT4-32K-Prompt
2.00    100 Image-DALL-E
0.36    1h  Speech-Whisper

* GeneratedTokens = Completion
* ProcessedPromptTokens = Prompt
* TokenTransaction = Completion + Prompt
* legacy models ada, babbage, curie, davinci, and cushman are not supported

#>