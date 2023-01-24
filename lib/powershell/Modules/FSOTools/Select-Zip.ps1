function Select-Zip {
    [CmdletBinding()]
    Param(
        $First,
        $Second,
        $ResultSelector = { ,$args }
    )

    [System.Linq.Enumerable]::Zip($First, $Second, [Func[Object, Object, Object[]]]$ResultSelector)
}