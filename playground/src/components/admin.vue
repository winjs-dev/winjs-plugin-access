<template>
    <div v-access="accessId">只有 Admin 可见</div>
</template>

<script setup lang="ts">
const accessId = '/admin';
</script>
